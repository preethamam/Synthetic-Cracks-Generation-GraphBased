#!/usr/bin/env python3
"""
crack_feature_factory.py
────────────────────────
Component‑level feature extraction pipeline for real‑world and synthetic
crack masks.

• Modular  – separate helpers for morphology, width, topology, contour
• Parallel – joblib + tqdm (thread‑safe, no monkey‑patch)
• Unified  – numeric features *and* simplified skeleton edge‑lists stored
             together in a single Parquet file

Author : Preetham Manjunatha
Created: 2025‑07‑25
"""
# ── standard libs ────────────────────────────────────────────────────────────
from __future__ import annotations
import random
import argparse
import functools
import itertools
import math
import time
from pathlib import Path
from typing import Any, Dict, List, Tuple

# ── third‑party libs ─────────────────────────────────────────────────────────
import networkx as nx
import numpy as np
import pandas as pd
from joblib import Parallel, delayed
from scipy import ndimage as ndi
from skimage import io, measure
from skimage.morphology import binary_opening, disk, skeletonize
from tqdm import auto as tqdm_auto

# ─────────────────────────────────────────────────────────────────────────────
# 1. Argument parsing
# ─────────────────────────────────────────────────────────────────────────────
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract component‑level crack features (numeric + graph)."
    )
    parser.add_argument(
        "--real_roots",
        nargs="+",
        default=[
            # DeepCrack – pixel labels
            Path(r"S:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels"),
            # Cracks‑1K – pixel labels
            Path(r"S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels"),
            # GSynCrack – pixel labels
            Path(r"S:\Project DLCRACK\My Datasets\Graph Synthetic Crack (GSynCrack - GSC)\Pixel Labels"),
        ],
        help="Root folders containing real mask sub‑folders (scanned recursively).",
    )
    parser.add_argument(
        "--synthetic_root",
        type=Path,
        default=Path(r"F:\Datasets\SyntheticCRACK\Paper 2a - A graph-based 2D binary images"),
        help="Parent folder whose sub‑directories are synthetic variants.",
    )
    parser.add_argument(
        "--min_area",
        type=int,
        default=25,
        help="Skip connected components smaller than this pixel area.",
    )
    parser.add_argument(
        "--synthetic_sample",
        type=int,
        default=15000,
        metavar="N",
        help="If >0, randomly sample N synthetic masks for a dry run. "
             "0 = use ALL synthetic images (default).",
    )
    parser.add_argument(
        "--n_jobs",
        type=int,
        default=-1,
        help="joblib workers (‑1 = use all available CPU cores).",
    )
    parser.add_argument(
        "--outfile",
        type=Path,
        default="crack_features_15000.parquet",
        help="Output Parquet filename.",
    )
    return parser.parse_args()


# ─────────────────────────────────────────────────────────────────────────────
# 2. Utility helpers
# ─────────────────────────────────────────────────────────────────────────────
def timer(func):
    """Print wall‑clock time for decorated function."""

    @functools.wraps(func)
    def _wrapper(*args, **kwargs):
        start = time.perf_counter()
        value = func(*args, **kwargs)
        end = time.perf_counter()
        print(f"[TIMER] {func.__name__:27s} {end - start:7.2f}s")
        return value

    return _wrapper


IMG_EXTS = {".png", ".bmp", ".jpg", ".jpeg", ".tif", ".tiff"}


def list_images(root: Path) -> List[Path]:
    """Recursively list image files under *root* with accepted extensions."""
    return [p for p in root.rglob("*") if p.suffix.lower() in IMG_EXTS]


# ─────────────────────────────────────────────────────────────────────────────
# 3. Feature family implementations
# ─────────────────────────────────────────────────────────────────────────────
def morphology_features(region: measure._regionprops.RegionProperties) -> Dict[str, float]:
    area, perim = region.area, region.perimeter
    convex = region.convex_area or 1
    width  = region.bbox[3] - region.bbox[1]
    height = region.bbox[2] - region.bbox[0]

    return {
        "area": area,
        "perimeter": perim,
        "compactness": perim**2 / (4 * np.pi * area),
        "solidity": area / convex,
        "bbox_ar": width / height if height else 0,
        "eccentricity": region.eccentricity,
        "major_axis": region.major_axis_length,
        "minor_axis": region.minor_axis_length,
        "orientation": float(np.deg2rad(region.orientation)),  # ⟵ add back
    } # type: ignore



def width_features(mask: np.ndarray, skel: np.ndarray) -> Dict[str, float]:
    """Distance‑transform‑based width statistics."""
    diameters = ndi.distance_transform_edt(mask)[skel] * 2.0
    if diameters.size == 0:
        return {"mean_w": 0, "max_w": 0, "std_w": 0}
    return {
        "mean_w": float(diameters.mean()),
        "max_w": float(diameters.max()),
        "std_w": float(diameters.std()),
    }


def simplify_graph(G: nx.Graph) -> nx.Graph:
    """
    Collapse all degree‑2 chains into a single edge.
    Keeps 'length' (Euclidean) and 'pix_len' (#pixels) as edge attributes.
    """
    H = nx.Graph()
    junctions = [n for n, d in G.degree() if d != 2]
    H.add_nodes_from(junctions)
    visited: set[tuple[int, int]] = set(junctions)

    for j in junctions:
        for nbr in G.neighbors(j):
            if nbr in visited:
                continue
            path = [j, nbr]
            prev, cur = j, nbr
            while G.degree(cur) == 2:
                nxt = next(n for n in G.neighbors(cur) if n != prev)
                path.append(nxt)
                prev, cur = cur, nxt
            seg_len = math.dist(path[0], path[-1])
            H.add_edge(j, cur, length=seg_len, pix_len=len(path))
            visited.update(path[1:-1])
    return H


def topology_features(skel: np.ndarray) -> Tuple[Dict[str, float], List[Tuple[int, ...]]]:
    """Graph metrics + edge list (handles empty graphs safely)."""
    # 8‑connected pixel graph
    G = nx.Graph()
    ys, xs = np.nonzero(skel)
    G.add_nodes_from([(int(y), int(x)) for y, x in zip(ys, xs)])
    for y, x in zip(ys, xs):
        for dy, dx in (
            (-1, 0), (1, 0), (0, -1), (0, 1),
            (-1, -1), (-1, 1), (1, -1), (1, 1)
        ):
            ny, nx_ = y + dy, x + dx
            if 0 <= ny < skel.shape[0] and 0 <= nx_ < skel.shape[1] and skel[ny, nx_]:
                G.add_edge((y, x), (ny, nx_))

    G_s = simplify_graph(G)

    # degree stats
    n_nodes = G_s.number_of_nodes()
    degrees = np.array([d for _, d in G_s.degree()]) if n_nodes else np.zeros(1)
    ends, branches = int((degrees == 1).sum()), int((degrees > 2).sum())

    # robust longest‑path estimate
    if n_nodes < 2 or G_s.number_of_edges() == 0:
        longest = 0
    else:
        try:
            longest = max(
                nx.diameter(G_s.subgraph(c)) for c in nx.connected_components(G_s)
            )
        except nx.exception.NetworkXError:
            longest = 0

    metrics = {
        "n_nodes": n_nodes,
        "n_edges": G_s.number_of_edges(),
        "n_end": ends,
        "n_branch": branches,
        "avg_deg": float(degrees.mean()),
        "deg_std": float(degrees.std()),
        "longest_path": int(longest),
        "branch_density": branches / n_nodes if n_nodes else 0,
        "cyclomatic": G_s.number_of_edges()
                     - n_nodes
                     + nx.number_connected_components(G_s),
        "clustering": nx.average_clustering(G_s) if G_s.number_of_edges() else 0,
    }

    edge_list = [
        (int(a[0]), int(a[1]), int(b[0]), int(b[1])) for a, b in G_s.edges()
    ]
    return metrics, edge_list


def contour_features(mask: np.ndarray) -> Dict[str, float]:
    """Fractal dimension + curvature stats of the largest contour."""
    contours = measure.find_contours(mask.astype(float), 0.5)
    if not contours:
        return {"fractal_dim": 0, "curv_mean": 0, "curv_std": 0}

    contour = max(contours, key=len)

    # fractal dimension: box‑count
    Z = mask.astype(bool)
    p = min(Z.shape)
    n = 2 ** np.floor(np.log2(p))
    sizes = 2 ** np.arange(int(np.log2(n)), 1, -1)
    counts = [
        np.add.reduceat(
            np.add.reduceat(Z, np.arange(0, Z.shape[0], k), axis=0),
            np.arange(0, Z.shape[1], k),
            axis=1,
        )
        .astype(bool)
        .sum()
        for k in sizes
    ]
    fd = -np.polyfit(np.log(sizes), np.log(counts), 1)[0]

    # curvature
    chain = contour
    dx, dy = np.gradient(chain[:, 1]), np.gradient(chain[:, 0])
    ddx, ddy = np.gradient(dx), np.gradient(dy)
    curvature = np.abs(dx * ddy - dy * ddx) / (dx * dx + dy * dy + 1e-8) ** 1.5

    return {
        "fractal_dim": fd,
        "curv_mean": float(curvature.mean()),
        "curv_std": float(curvature.std()),
    }


# ─────────────────────────────────────────────────────────────────────────────
# 4. Per‑image feature extraction
# ─────────────────────────────────────────────────────────────────────────────
def extract_image(
    mask_path: Path, dataset_lbl: str, min_area: int
) -> List[Dict[str, Any]]:
    """Return a record per connected component in *mask_path*."""
    mask = io.imread(mask_path, as_gray=True) > 0.5
    mask = binary_opening(mask, disk(1))
    labeled = measure.label(mask, connectivity=2)

    records: List[Dict[str, Any]] = []
    for region in measure.regionprops(labeled):
        if region.area < min_area:
            continue

        comp_mask = labeled == region.label
        skel = skeletonize(comp_mask)

        topo_metrics, edge_list = topology_features(skel)

        rec: Dict[str, Any] = {
            "image_id": mask_path.name,
            "comp_id": int(region.label),
            "dataset": dataset_lbl,
            "edges": edge_list,
        }
        rec.update(morphology_features(region))
        rec.update(width_features(comp_mask, skel))
        rec.update(topo_metrics)
        rec.update(contour_features(comp_mask))

        # derived, scale‑free ratios
        rec["w2l_ratio"] = rec["mean_w"] / (rec["major_axis"] + 1e-3)
        rec["norm_area"] = rec["area"] / mask.size
        rec["branch_per_px"] = rec["n_branch"] / (rec["area"] + 1e-3)

        records.append(rec)

    return records


# ─────────────────────────────────────────────────────────────────────────────
# 5. Main pipeline
# ─────────────────────────────────────────────────────────────────────────────
@timer
def main() -> None:
    args = parse_args()

    # 5.1 enumerate image masks with dataset labels
    paths_labels: List[Tuple[Path, str]] = []
    for root in args.real_roots:
        root_path = Path(root)
        paths_labels += [(p, root_path.stem) for p in list_images(root_path)]

    # ── collect synthetic masks ─────────────────────────────────────────
    syn_paths: List[Tuple[Path, str]] = []        # (path, dataset_label)

    for sub in sorted(args.synthetic_root.iterdir()):
        if not sub.is_dir():
            continue

        all_files = list_images(sub)
        label = f"syn_{sub.stem.lower()}"

        if args.synthetic_sample > 0 and len(all_files) > args.synthetic_sample:
            random.seed(42)                       # reproducible across runs
            chosen = random.sample(all_files, args.synthetic_sample)
            print(f"[INFO] {label:20s} sampled {len(chosen):5d} / {len(all_files):,} masks")
        else:
            chosen = all_files                    # take everything
            print(f"[INFO] {label:20s} using    {len(chosen):5d} masks (full set)")

        # tag each path with its sub‑folder label
        syn_paths.extend((p, label) for p in chosen)

    # tag each synthetic path with its sub‑folder label
    paths_labels += syn_paths

    print(f"[INFO] Total masks discovered: {len(paths_labels):,}")

    # 5.2 parallel extraction
    pbar = tqdm_auto.tqdm(total=len(paths_labels), desc="Extracting")
    def _worker(pl):
        path, lbl = pl
        recs = extract_image(path, lbl, args.min_area)
        pbar.update(1)
        return recs

    nested_records = Parallel(n_jobs=args.n_jobs, prefer="threads")(
        delayed(_worker)(pl) for pl in paths_labels
    )
    pbar.close()

    # 5.3 flatten & save
    df = pd.DataFrame(itertools.chain.from_iterable(nested_records))
    print(f"[INFO] Components kept: {len(df):,}")
    df.to_parquet(args.outfile, index=False)
    print(f"[OUT ] Features saved → {args.outfile.resolve()}")

    # 5.4 simple summary
    print("\n[SUMMARY]")
    print(df.groupby("dataset")["comp_id"].size())


# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    main()
