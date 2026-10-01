#!/usr/bin/env python3
"""
compute_global_metrics.py
─────────────────────────
FID · MMD² · Coverage95 · Density95  between all real‑world cracks and
all synthetic cracks, per feature family.

Outputs a CSV + pretty console table.
"""
from pathlib import Path
import argparse, warnings
import numpy as np, pandas as pd, scipy.linalg as la
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import pairwise_distances, pairwise_kernels
from sklearn.decomposition import PCA
from sklearn.neighbors import NearestNeighbors
import numpy.random as npr

# ── 1. CLI ────────────────────────────────────────────────────────────────
def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--features", type=Path, default="crack_features_25000.parquet")
    p.add_argument("--family", choices=["morphology","width","topology","contour","all"],
                   default="all", help="Which feature subset to use")
    p.add_argument("--pca", type=int, default=0, metavar="D",
                   help="Optional PCA dim (0 = no PCA)")
    p.add_argument("--rename", default="",
                   help='Inline rename map "Pixel Labels:Real, syn_longitudinal:Syn.L"')
    p.add_argument("--outfile", type=Path, default="global_metrics.csv")
    p.add_argument("--max_mmd", type=int, default=0,
                   help="Subsample size for quadratic MMD; 0 = linear estimator")
    return p.parse_args()

# ── 2. same rename helpers as your visualiser ────────────────────────────
def parse_rename(s: str) -> dict[str,str]:
    if not s: return {}
    d = {}
    for kv in s.split(","):
        if ":" in kv:
            k,v = kv.split(":",1)
            d[k.strip()] = v.strip()
    return d

def pretty_label(raw: str, user_map: dict[str,str]) -> str:
    if raw in user_map: return user_map[raw]
    if raw.lower().startswith("pixel labels"): return "Real‑world Data"
    if raw.startswith("syn_"):
        default = {
            "longitudinal":"Syn. Long.","transverse":"Syn. Trans.",
            "branched":"Syn. Branch.","surface":"Syn. Surf.",
            "rrt":"Syn. RRT","rrtstar":"Syn. RRT*","shear":"Syn. Shear",
            "fati":"Syn. Fati."
        }
        return default.get(raw[4:], f"Syn. {raw[4:].title()}")
    return raw

# ── 3. feature families ───────────────────────────────────────────────────
FAM_COLS = {
    "morphology" : ["area","perimeter","compactness","solidity",
                    "bbox_ar","eccentricity","major_axis","minor_axis","orientation"],
    "width"      : ["mean_w","max_w","std_w"],
    "topology"   : ["n_nodes","n_edges","n_end","n_branch",
                    "avg_deg","deg_std","longest_path",
                    "branch_density","cyclomatic","clustering"],
    "contour"    : ["fractal_dim","curv_mean","curv_std"],
}

# ── 4. metric helpers ─────────────────────────────────────────────────────
def fid(Xr, Xs):
    mu_r, mu_s = Xr.mean(0), Xs.mean(0)
    cov_r, cov_s = np.cov(Xr, rowvar=False), np.cov(Xs, rowvar=False)
    sqrt_cov, _ = la.sqrtm(cov_r @ cov_s, disp=False)
    return np.sum((mu_r - mu_s)**2) + np.trace(cov_r + cov_s - 2*sqrt_cov.real)

def mmd2_gaussian(Xr, Xs, max_mmd=10000, seed=0):
    """Finite‑sample MMD² with optional subsampling or linear estimator."""
    if max_mmd and (len(Xr) > max_mmd or len(Xs) > max_mmd):
        npr.seed(seed)
        Xr = Xr[npr.choice(len(Xr), max_mmd, replace=False)]
        Xs = Xs[npr.choice(len(Xs), max_mmd, replace=False)]

    if max_mmd == 0:
        # linear‑time unbiased estimator (Gretton 2012) using one‑pass pairing
        m = min(len(Xr), len(Xs))
        Xr, Xs = Xr[:m], Xs[:m]
        sigma = np.median(pairwise_distances(
            np.vstack([Xr[:1000], Xs[:1000]])))
        gamma = 1/(2*sigma**2)
        k = lambda A,B: np.exp(-gamma*((A-B)**2).sum())  # rbf scalar
        s1 = sum(k(Xr[i], Xr[(i+1)%m]) + k(Xs[i], Xs[(i+1)%m])
                 - k(Xr[i], Xs[(i+1)%m]) - k(Xr[(i+1)%m], Xs[i])
                 for i in range(m))
        return s1 / m
    else:
        # quadratic but on subsample
        sigma = np.median(pairwise_distances(
            np.vstack([Xr[:1000], Xs[:1000]])))
        gamma = 1/(2*sigma**2)
        K_rr = pairwise_kernels(Xr, Xr, metric="rbf", gamma=gamma).mean()
        K_ss = pairwise_kernels(Xs, Xs, metric="rbf", gamma=gamma).mean()
        K_rs = pairwise_kernels(Xr, Xs, metric="rbf", gamma=gamma).mean()
        return K_rr + K_ss - 2*K_rs


def cov_den95_nn(Xr, Xs, batch=50000):
    """95‑th percentile nearest‑neighbour distances using sklearn NN."""
    nn_s = NearestNeighbors(n_neighbors=1, algorithm="auto").fit(Xs)
    nn_r = NearestNeighbors(n_neighbors=1, algorithm="auto").fit(Xr)

    # real → syn
    d_r2s = np.concatenate([
        nn_s.kneighbors(Xr[i:i+batch], return_distance=True)[0].ravel()
        for i in range(0, len(Xr), batch)
    ])
    # syn → real
    d_s2r = np.concatenate([
        nn_r.kneighbors(Xs[i:i+batch], return_distance=True)[0].ravel()
        for i in range(0, len(Xs), batch)
    ])
    return np.quantile(d_r2s, .95), np.quantile(d_s2r, .95)

# ── 5. main ───────────────────────────────────────────────────────────────
def main():
    args = parse_args()
    df = pd.read_parquet(args.features)

    # rename labels
    rename_map = parse_rename(args.rename)
    df["label"] = df["dataset"].apply(lambda r: pretty_label(r, rename_map))

    fam_list = FAM_COLS.keys() if args.family == "all" else [args.family]
    rows = []

    for fam in fam_list:
        cols = FAM_COLS[fam]
        X = df[cols].fillna(0).values
        X = StandardScaler().fit_transform(X)
        if args.pca:
            X = PCA(args.pca, random_state=0).fit_transform(X)

        X_real = X[df["label"] == "Real‑world Data"]
        X_syn  = X[df["label"] != "Real‑world Data"]

        row = {
            "family": fam,
            "n_real": len(X_real),
            "n_syn":  len(X_syn),
            "FID":    fid(X_real, X_syn),
            "MMD2":   mmd2_gaussian(X_real, X_syn, max_mmd=args.max_mmd),
        }
        cov95, den95 = cov_den95_nn(X_real, X_syn)
        row["Coverage95"] = cov95
        row["Density95"]  = den95
        rows.append(row)

    table = pd.DataFrame(rows)
    # nice console print
    print("\nGlobal Metrics (real vs ALL synthetic)\n")
    print(table.to_string(index=False, float_format="%.4f"))

    table.to_csv(args.outfile, index=False)
    print(f"\n[OUT] CSV saved → {args.outfile.resolve()}")

if __name__ == "__main__":
    warnings.filterwarnings("ignore", category=RuntimeWarning)  # sqrtm tiny imag parts
    main()
