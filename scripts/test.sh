#!/usr/bin/env bash
# Runs the Luau tests. Needs the `luau` CLI on your PATH:
# https://github.com/luau-lang/luau/releases (download luau-<os>.zip and unzip it).
set -euo pipefail
cd "$(dirname "$0")/.."
luau tests/run.luau
