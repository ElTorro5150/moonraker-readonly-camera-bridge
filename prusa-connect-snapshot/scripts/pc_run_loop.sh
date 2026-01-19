#!/usr/bin/env bash
# Wrapper kept for backward compatibility.
# Source of truth: prusa-connect-snapshot/bin/pc_run_loop.sh
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/pc_run_loop.sh" "$@"
