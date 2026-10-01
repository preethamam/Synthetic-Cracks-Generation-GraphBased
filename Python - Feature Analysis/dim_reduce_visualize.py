#!/usr/bin/env python3
"""
dim_reduce_visualize.py   · Part 2
────────────────────────────────────────────────────────────
Creates PCA (2‑D) scatter plots for each feature family:
  • Morphology
  • Width
  • Topology
  • Contour

All figures saved as cropped‑margin PDFs with the legend *inside* the plot.

Usage example
-------------
python dim_reduce_visualize.py --features crack_features.parquet --outdir viz_out

Author : Preetham Manjunatha
Created: 2025‑07‑25
"""
# ── std libs ────────────────────────────────────────────────────────────────
import argparse, time, sys
from pathlib import Path
# ── 3rd‑party ───────────────────────────────────────────────────────────────
import matplotlib
matplotlib.use("Agg")          # ← non-interactive backend (no Tk)
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import seaborn as sns
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
# optional t‑SNE / UMAP per‑family on demand
from sklearn.manifold import TSNE
try:
    import umap
    HAS_UMAP = True
except ImportError:
    HAS_UMAP = False
# ────────────────────────────────────────────────────────────────────────────

# ── add near other imports
import warnings

# silence the specific UMAP single‑thread notice
warnings.filterwarnings(
    "ignore",
    message="n_jobs value 1 overridden",
    category=UserWarning,
)

# ------------------------------------------------------------------ CLI
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser("Per‑family PCA scatter visualiser")
    p.add_argument("--features", type=Path, default="crack_features_25000.parquet")
    p.add_argument("--outdir",   type=Path, default="viz_outputs")
    p.add_argument("--sample",   type=int,  default=0,
                   help="Sub‑sample rows for speed; 0 = all")
    p.add_argument("--rename",   default="",
                   help='Inline rename map "Pixel Labels:Real, syn_longitudinal:Syn.L"')
    p.add_argument(
        "--plots",
        nargs="*",
        choices=["pca", "tsne", "umap", "kde"],
        default=["tsne", "umap"],
        help=("Plot types to generate. Multiply selectable, e.g. "
              "'--plots pca tsne'.  Default = all four."),
    )
    p.add_argument("--alpha_other", type=float, default=1.0,
                   help="Alpha (0‑1) for non‑real points")
    p.add_argument("--alpha_real",  type=float, default=1.0,
                   help="Alpha (0‑1) for 'Real‑world Data' points")
    p.add_argument("--suffix",   type=str, default="_25000")
    return p.parse_args()

# ------------------------------------------------------------------ rename helpers
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


# ------------------------------------------------------------------ plotting
def scatter_pdf(
    emb,
    labels,
    title,
    out_path: Path,
    legend_outside: bool = False,          # ← NEW optional flag
    alpha_other: float = .25,       # NEW
    alpha_real:  float = 1.00,
):
    plt.figure(figsize=(6, 5))
    ax = sns.scatterplot(
        x=emb[:, 0], y=emb[:, 1], hue=labels,
        s=8, linewidth=0, alpha=.8, legend="full"
    )
    for coll, lab in zip(ax.collections, pd.unique(labels)):
        if lab == "Real‑world Data":           # exact pretty‑label string
            coll.set_alpha(alpha_real)
        else:
            coll.set_alpha(alpha_other)
            
    plt.xlabel("Dimension 1"); plt.ylabel("Dimension 2")

    if legend_outside:
        # put legend outside, centred above, multi‑column
        ncol = 4
        plt.legend(
            loc="upper center", bbox_to_anchor=(0.5, 1.12),
            ncol=ncol, fontsize=8, framealpha=.9, markerscale=2
        )    
    else:
        # strip legend entirely
        ax.get_legend().remove()

    plt.tight_layout()
    plt.savefig(out_path, dpi=300, bbox_inches="tight", pad_inches=0)
    plt.close()
    print(f"[OUT ] {out_path.name}")


# ------------------------------------------------------------------ main
def main():
    args = parse_args()
    args.outdir.mkdir(parents=True, exist_ok=True)

    # load & (optionally) sample
    df = pd.read_parquet(args.features)
    if args.sample and len(df) > args.sample:
        df = df.sample(args.sample, random_state=42)
        print(f"[INFO] Sampled {len(df):,} rows")

    # rename labels
    rename_dict = parse_rename(args.rename)
    df["label"] = df["dataset"].apply(lambda r: pretty_label(r, rename_dict))

    # --- define feature families ------------------------------------------
    fam_cols = {
        "morphology": [c for c in df.columns if c in
                       ("area","perimeter","compactness","solidity",
                        "bbox_ar","eccentricity","major_axis","minor_axis",
                        "orientation")],
        "width":      [c for c in df.columns if c.startswith(("mean_w","max_w","std_w"))],
        "topology":   [c for c in df.columns if c.startswith(("n_","avg_deg","deg_std",
                         "longest_path","branch_density","cyclomatic","clustering"))],
        "contour":    [c for c in df.columns if c.startswith(("fractal_dim","curv_"))],
    }    
    
    for fam, cols in fam_cols.items():
        
        legend_flag = True #(fam == "morphology")   # outside legend just for morphology
        
        if not cols: continue
        # standardise
        X = df[cols].fillna(0.0).values
        X_std = StandardScaler().fit_transform(X)
        # X_std += np.random.normal(0, 1e-3, X_std.shape)  # Jitter to avoid same feature values

       # always compute standardized feature matrix X_std ...

        # ---------------- PCA ----------------
        if "pca" in args.plots:
            emb_pca = PCA(n_components=2, random_state=0).fit_transform(X_std)
            scatter_pdf(
                emb_pca, df["label"],
                f"PCA – {fam.title()} Features",
                args.outdir / f"pca_{fam}{args.suffix}.pdf",
                legend_outside=legend_flag,
                alpha_other=args.alpha_other,
                alpha_real=args.alpha_real
            )

        # ---------------- t‑SNE --------------
        if "tsne" in args.plots:
            emb_tsne = TSNE(
                n_components=2, perplexity=30, random_state=0,
                init="pca", learning_rate="auto"
            ).fit_transform(X_std)
            scatter_pdf(
                emb_tsne, df["label"],
                f"t‑SNE – {fam.title()}",
                args.outdir / f"tsne_{fam}{args.suffix}.pdf",
                legend_outside=legend_flag,
                alpha_other=args.alpha_other,
                alpha_real=args.alpha_real
            )

        # ---------------- UMAP ---------------
        if "umap" in args.plots and HAS_UMAP:
            emb_umap = umap.UMAP(n_components=2).fit_transform(X_std)   # ← no random_state
            scatter_pdf(
                emb_umap, df["label"],
                f"UMAP – {fam.title()}",
                args.outdir / f"umap_{fam}{args.suffix}.pdf",
                legend_outside=legend_flag,
                alpha_other=args.alpha_other,
                alpha_real=args.alpha_real
            )

        # ---------------- KDE ----------------
        if "kde" in args.plots:
            sub_cols = cols[:4] if len(cols) > 4 else cols
            g = sns.pairplot(
                df[["label"] + sub_cols],
                vars=sub_cols, hue="label",
                kind="kde", diag_kind="kde",
                plot_kws={"alpha": 0.6}          # ← linewidth removed
            )
            g.fig.suptitle(
                f"KDE Grid – {fam.title()} (first {len(sub_cols)} features)", y=1.02
            )
            out_pdf = args.outdir / f"kde_{fam}{args.suffix}.pdf"
            g.savefig(out_pdf, dpi=300, bbox_inches="tight", pad_inches=0)
            plt.close()
            print(f"[OUT ] {out_pdf.name}")


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    t0 = time.perf_counter()
    main()
    print(f"[DONE] total run‑time {time.perf_counter()-t0:6.1f}s")