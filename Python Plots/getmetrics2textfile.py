#!/usr/bin/env python3
"""
Parse CDLN result files and write MATLAB object–wise (Pixels) metrics
to a LaTeX‑ready text file as well as stdout.

2025‑07‑23
"""

import re, sys, pathlib
from typing import Dict, List

# --------------------------------------------------------------------------- #
# User‑configurable paths
# --------------------------------------------------------------------------- #
ROOT_FOLDER = pathlib.Path(r"D:\OneDrive\Education Materials\Team Work\Team SyntheticCRACK\Codebase\2022-01-22 - A graph-based (non-force)\Results\Text Files\Ablation")          # default search folder
OUT_FILE    = "gsc_LaTeX_table_entries_ablation.txt"   # final merged text
TXT_FILES = "pp_hybrid_morpho_marathon_GSC_*.txt"

# --------------------------------------------------------------------------- #
# Regex helpers (unchanged)
# --------------------------------------------------------------------------- #
ALGO_START = re.compile(r'^Algorithm type:\s*(\S+)', re.I)
MATLAB_PIX = re.compile(r'Each object wise \(Pixels\) classification results by MATLAB', re.I)
_NUM       = r'([\d.]+|NaN)'
PREC_RE    = re.compile(r'^\s*Precision\s+' + r'\s+'.join([_NUM]*3))
RECALL_RE  = re.compile(r'^\s*Recall\s+'    + r'\s+'.join([_NUM]*3))
F1_RE      = re.compile(r'^\s*F1score\s+'   + r'\s+'.join([_NUM]*3))
MEAN_RE    = re.compile(r'^\s*MeanIoU\s+'   + r'\s+'.join([_NUM]*3))

ALGO_PRETTY = {
    "hybrid_hessian": "Hessian",
    "hybrid_MFAT":    "MFAT",
    "morpho":         "Morpho",
}
ALGO_ORDER = ["hybrid_hessian", "hybrid_MFAT", "morpho"]

# DATA_CLASS = {
#     1: "1 million+ synthetic cracks",
#     2: "100000 synthetic cracks",
#     3: "Real‑world only",
#     4: "Real‑world augmented only",
#     5: "Real‑world + Real‑world augmented",
#     6: "Real‑world + Real‑world augmented + synthetic",
# }

DATA_CLASS = {
    1: "One-pixel wide",
    2: "With morphological dilation",
    3: "With geometric transformation",
    4: "With elastic deformation"
}

# --------------------------------------------------------------------------- #
# Parsing helpers
# --------------------------------------------------------------------------- #
def parse_file(path: pathlib.Path) -> Dict[str, Dict[str, List[float]]]:
    """Return {algo_tag: {metric: [ANN,KNN,SVM]}} for one file."""
    out: Dict[str, Dict[str, List[float]]] = {}
    lines = path.read_text().splitlines()
    i = 0
    while i < len(lines):
        m_algo = ALGO_START.match(lines[i])
        if not m_algo:
            i += 1
            continue
        tag = m_algo.group(1)

        # Seek MATLAB Pixels section
        while i < len(lines) and not MATLAB_PIX.search(lines[i]):
            i += 1
        if i >= len(lines):           # section not found
            break

        metrics = {}
        while i < len(lines):
            if ALGO_START.match(lines[i]) and i != 0:  # next block begins
                i -= 1
                break
            for rgx, key in [(PREC_RE,"Precision"),(RECALL_RE,"Recall"),
                             (F1_RE,"F1score"),(MEAN_RE,"MeanIoU")]:
                m = rgx.match(lines[i])
                if m:
                    metrics[key] = [float(x) for x in m.groups()]
            if "MeanIoU" in metrics:      # got the four rows
                break
            i += 1

        if {"Precision","Recall","F1score","MeanIoU"} <= metrics.keys():
            out[tag] = metrics
        i += 1
    return out


def format_table(data_class: str,
                 by_algo: Dict[str, Dict[str, List[float]]]) -> str:
    """Return one data‑class block as a multi‑line string."""
    block_lines = [f"Data class: {data_class}"]
    for tag in ALGO_ORDER:
        if tag not in by_algo:           # skip if not present
            continue
        block_lines.append(f"Algorithm type: {ALGO_PRETTY[tag]}")
        block_lines.append("-"*75)
        block_lines.append("Classifier name      ANN           KNN            SVM ")
        block_lines.append("-"*75)
        for key in ["Precision","Recall","F1score","MeanIoU"]:
            a,k,s = by_algo[tag][key]
            block_lines.append(f"{key:<18}{a:>7.4f}         {k:>7.4f}         {s:>7.4f}")
        block_lines.append("")           # blank line between algorithms
    block_lines.append("")               # blank line between data‑classes
    return "\n".join(block_lines)


# --------------------------------------------------------------------------- #
def main(root: pathlib.Path) -> None:
    if not root.exists():
        sys.exit(f"[ERROR] ROOT_FOLDER {root} does not exist")

    # Collect files, skip the dummy “0”
    files = sorted(root.glob(TXT_FILES),
                   key=lambda p: int(p.stem.split("_")[-1]))
    files = [f for f in files if f.stem.split("_")[-1] != "0"]

    if len(files) < 6:
        print("[WARN] Fewer than 6 real files found (dummy skipped)")

    all_blocks: List[str] = []           # gather text for file output

    for f in files:
        idx = int(f.stem.split("_")[-1])
        print(f"[INFO] Parsing {f.name}")
        tbl = format_table(DATA_CLASS.get(idx,f'Test‑case {idx}'),
                           parse_file(f))
        print(tbl)
        all_blocks.append(tbl)

    # -----------------------------------------------------------------------
    # Write consolidated file
    out_path = root / OUT_FILE
    out_path.write_text("\n".join(all_blocks), encoding="utf-8")
    print(f"[DONE] Results saved to {out_path.resolve()}")


if __name__ == "__main__":
    root_dir = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT_FOLDER
    main(root_dir.resolve())
