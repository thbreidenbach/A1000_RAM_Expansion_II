#!/usr/bin/env bash
set -euo pipefail

# build.sh - command line ISE flow for XC9500XL CPLDs
#
# Requires Xilinx ISE (e.g. 14.7) with command-line tools in PATH:
#   xst, ngdbuild, cpldfit, hprep6
#
# Output: a1000_frontram.jed (JEDEC), a1000_frontram.svf (SVF) for JTAG programming.

PROJECT="a1000_frontram"
PART="XC9572XL-10-VQ64"

echo "[1/4] Synth (xst)"
xst -ifn ${PROJECT}.xst -ofn ${PROJECT}.syr

echo "[2/4] NGDBuild"
ngdbuild -p ${PART} -uc ${PROJECT}.ucf ${PROJECT}.ngc ${PROJECT}.ngd

echo "[3/4] Fit (cpldfit)"
cpldfit -p ${PART} -optimize speed -loc on -tmd off ${PROJECT}.ngd

echo "[4/4] Generate SVF (hprep6)"
hprep6 -s IEEE1149 -n ${PROJECT} -i ${PROJECT}

echo "Done. Artifacts:"
ls -1 ${PROJECT}.jed ${PROJECT}.svf 2>/dev/null || true
