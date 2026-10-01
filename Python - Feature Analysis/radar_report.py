#!/usr/bin/env python3
"""
radar_report.py   · Part 3
────────────────────────────────────────────────────────────
Aggregate feature medians per dataset and render publication‑quality
radar / spider charts for each feature family.

• Legend inside plot
• PDF output, bbox_inches="tight"
• Inline rename map via --rename (same syntax as Part 2)

Author : <your‑name>
Created: 2025‑07‑25
"""
# ── std libs ───────────────────────────────────────────────────────────────
import argparse, math
from pathlib import Path
from typing import Dict, List

# ── 3rd‑party ──────────────────────────────────────────────────────────────
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

# ───────────────────────────────────────────────────────────────────────────
# 1. CLI
# ───────────────────────────────────────────────────────────────────────────
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser("Generate radar charts for crack feature medians")
    p.add_argument("--features", type=Path, default="crack_features.parquet")
    p.add_argument("--outdir",   type=Path, default="viz_outputs")
    p.add_argument("--rename",   default="",
                   help='Inline rename map "Pixel Labels:Real, syn_longitudinal:Syn.L"')
    return p.parse_args()


# ───────────────────────────────────────────────────────────────────────────
# 2. Renaming helpers (reuse logic from Part 2)
# ───────────────────────────────────────────────────────────────────────────
def parse_rename(s: str) -> Dict[str, str]:
    if not s:
        return {}
    m: Dict[str, str] = {}
    for pair in s.split(","):
        if ":" in pair:
            k, v = pair.split(":", 1)
            m[k.strip()] = v.strip()
    return m

def pretty_label(raw: str, user_map: Dict[str, str]) -> str:
    if raw in user_map:
        return user_map[raw]
    if raw.lower().startswith("pixel labels"):
        return "Real‑world Data"
    if raw.startswith("syn_"):
        abbrev = {
            "longitudinal":"Syn. Long.","transverse":"Syn. Trans.",
            "branched":"Syn. Branch.","surface":"Syn. Surf.",
            "rrt":"Syn. RRT","rrtstar":"Syn. RRT*",
            "shear":"Syn. Shear","fati":"Syn. Fati."
        }
        return abbrev.get(raw[4:], f"Syn. {raw[4:].title()}")
    return raw


# ───────────────────────────────────────────────────────────────────────────
# 3. Radar‑plot utility
# ───────────────────────────────────────────────────────────────────────────
def radar_factory(num_vars: int, frame: str = "circle"):
    """Return a matplotlib projection for radar plots."""
    from matplotlib.projections.polar import PolarAxes
    from matplotlib.projections import register_projection

    theta = np.linspace(0, 2 * np.pi, num_vars, endpoint=False)

    class RadarAxes(PolarAxes):
        name = "radar"
        # rotate labels so the first axis is at the top
        theta_offset = np.pi / 2
        theta_direction = -1

        def draw_frame(self, x):
            pass  # overridden by patch

        def set_varlabels(self, labels):
            self.set_thetagrids(np.degrees(theta), labels, fontsize=9)

    if frame == "circle":
        def _gen_axes_patch(self):
            return plt.Circle((0.5, 0.5), 0.5)
        RadarAxes.draw_frame = _gen_axes_patch

    register_projection(RadarAxes)
    return theta


def plot_radar(family: str,
               features: List[str],
               medians: pd.DataFrame,
               out_path: Path):
    """Draw radar chart and save as PDF."""
    theta = radar_factory(len(features))
    fig, ax = plt.subplots(subplot_kw=dict(projection="radar"), figsize=(6, 6))

    # rescale each spoke to [0,1] across datasets for comparability
    med_norm = (medians - medians.min()) / (medians.max() - medians.min() + 1e-9)

    # palette for up to 10 classes
    palette = sns.color_palette("tab10", len(med_norm))
    for idx, (label, row) in enumerate(med_norm.iterrows()):
        values = row.values
        ax.plot(theta, values, color=palette[idx], label=label, linewidth=1.6)
        ax.fill(theta, values, color=palette[idx], alpha=0.15)

    ax.set_varlabels(features)
    ax.set_title(f"{family.title()} Feature Medians", fontsize=13, pad=20)
    # legend inside plot, upper‑right
    ax.legend(loc="upper right", bbox_to_anchor=(1.2, 1.1), fontsize=8, framealpha=.9)
    plt.tight_layout()
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print(f"[OUT ] {out_path.name}")


# ───────────────────────────────────────────────────────────────────────────
# 4. Main
# ───────────────────────────────────────────────────────────────────────────
def main():
    args = parse_args()
    args.outdir.mkdir(parents=True, exist_ok=True)

    df = pd.read_parquet(args.features)
    rename_map = parse_rename(args.rename)
    df["label"] = df["dataset"].apply(lambda r: pretty_label(r, rename_map))

    # feature family columns
    fam_cols = {
        "morphology": [c for c in df.columns if c in
                       ("area","perimeter","compactness","solidity",
                        "bbox_ar","eccentricity","major_axis","minor_axis")],
        "width":      [c for c in df.columns if c.startswith(("mean_w","max_w","std_w"))],
        "topology":   [c for c in df.columns if c.startswith((
                        "n_nodes","n_edges","n_end","n_branch",
                        "avg_deg","deg_std","longest_path",
                        "branch_density","cyclomatic","clustering"))],
        "contour":    [c for c in df.columns if c.startswith(("fractal_dim","curv_"))],
    }

    for fam, cols in fam_cols.items():
        if not cols:
            continue

        # compute medians per dataset
        med = df.groupby("label")[cols].median()

        # limit to top 5 spokes by variance for visual clarity
        spokes = med.var().sort_values(ascending=False).head(5).index.tolist()

        plot_radar(
            fam, spokes, med[spokes],
            args.outdir / f"radar_{fam}.pdf"
        )


# ───────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    main()
