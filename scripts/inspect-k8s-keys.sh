#!/usr/bin/env sh
# List key paths only; never dump values that may contain Kubernetes Secrets.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
"$script_dir/kind-etcdctl.sh" get /registry --prefix --keys-only --limit=100
