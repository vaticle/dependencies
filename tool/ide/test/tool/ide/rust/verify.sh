#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/../../.."

bazel run @typedb_dependencies//tool/ide:rust_sync -- @test_workspace_refs//:refs.json

CHANGED="$(git status --porcelain -- . | grep 'Cargo\.toml' || true)"
if [ -n "$CHANGED" ]; then
    echo "$CHANGED"
    git --no-pager diff -- '*Cargo.toml*'
    echo "VERIFY FAILED: generated Cargo.toml files differ from the committed ones" >&2
    exit 1
fi
echo "VERIFY PASSED"
