#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Fuzzy-BKT Analysis Pipeline ==="
echo "Started: $(date)"

echo "[1/5] Loading data..."
Rscript R/src/01-load-data.R

echo "[2/5] Fitting BKT..."
Rscript R/src/02-fit-bkt.R

echo "[3/5] Fuzzy extension..."
Rscript R/src/03-fuzzy-extension.R

echo "[4/5] Cognitive offloading analysis..."
Rscript R/src/04-cognitive-offloading.R

echo "[5/5] Creating figures..."
Rscript R/src/05-visualize.R

echo "=== Pipeline complete ==="
echo "Finished: $(date)"
echo "Check R/output/ for results"
