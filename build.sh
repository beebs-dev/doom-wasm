#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
docker build --push -t thavlik/doom-wasm:latest .