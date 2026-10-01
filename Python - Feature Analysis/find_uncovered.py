#!/usr/bin/env python3
"""
find_uncovered.py
─────────────────
List real‑world crack components whose feature vector is farther than a
distance threshold from *every* synthetic component in a chosen feature family.
"""
import argparse, numpy as np, pandas as pd
from pathlib import Path
from sklearn.metrics import pairwise_distances
from sklearn.preprocessing import StandardScaler

FAM_MAP = {
    "morphology": ["area","perimeter","compactness","solidity",
                   "bbox_ar","eccentricity","major_axis","minor_axis"],
    "width":      ["mean_w","max_w","std_w"],
    "topology":   ["n_nodes","n_edges","n_end","n_branch",
                   "avg_deg","deg_std","longest_path",
                   "branch_density","cyclomatic","clustering"],
    "contour":    ["fractal_dim","curv_mean","curv_std"],
}

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--features", default="crack_features.parquet")
    p.add_argument("--family",   choices=FAM_MAP.keys(), default="width")
    p.add_argument("--tau",      type=float, default=None,
                   help="Distance threshold. If omitted, uses 95th‑quantile.")
    p.add_argument("--top_k",    type=int, default=20,
                   help="Number of most distant components to list.")
    return p.parse_args()

def main():
    args = parse_args()
    df = pd.read_parquet(args.features)

    cols = FAM_MAP[args.family]
    X = df[cols].fillna(0).values
    X = StandardScaler().fit_transform(X)   # same scaling used in t‑SNE step

    real_mask = df["label"] == "Real‑world Data"
    X_real = X[real_mask]
    X_syn  = X[~real_mask]

    # pairwise distances real × synthetic, but streaming to save RAM
    print("[INFO] computing nearest‑neighbour distances …")
    dists = []
    batch = 5000
    for i in range(0, len(X_real), batch):
        d = pairwise_distances(X_real[i:i+batch], X_syn, metric="euclidean", n_jobs=-1)
        dists.append(d.min(axis=1))
    nn_dist = np.concatenate(dists)

    # pick threshold
    tau = args.tau if args.tau is not None else np.quantile(nn_dist, 0.95)
    print(f"[INFO] threshold τ = {tau:.3f}")

    uncovered_idx = np.where(nn_dist > tau)[0]
    print(f"[INFO] uncovered components: {len(uncovered_idx):,}")

    # add distance column back into df subset
    df_uncovered = df.loc[real_mask].iloc[uncovered_idx].copy()
    df_uncovered["dist_to_syn"] = nn_dist[uncovered_idx]
    df_uncovered = df_uncovered.sort_values("dist_to_syn", ascending=False)

    # display / save top‑k
    top = df_uncovered.head(args.top_k)[
        ["image_id", "comp_id", "dist_to_syn"] + cols
    ]
    print(top.to_string(index=False))

    out_csv = Path(f"uncovered_{args.family}.csv")
    df_uncovered.to_csv(out_csv, index=False)
    print(f"[OUT] full list → {out_csv.resolve()}")

if __name__ == "__main__":
    main()
