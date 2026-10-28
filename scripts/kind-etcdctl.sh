#!/usr/bin/env sh
# Run etcdctl inside the kind control-plane node using its local client certs.
# Usage: KIND_CLUSTER_NAME=k8s-deepdive sh scripts/kind-etcdctl.sh endpoint status -w table
set -eu

cluster_name=${KIND_CLUSTER_NAME:-k8s-deepdive}
node_container="${cluster_name}-control-plane"

if [ "$#" -eq 0 ]; then
  echo "Pass etcdctl arguments, for example: endpoint status -w table" >&2
  exit 2
fi

docker inspect "$node_container" >/dev/null 2>&1 || {
  echo "kind node container not found: $node_container" >&2
  echo "Create the cluster or set KIND_CLUSTER_NAME to its kind name." >&2
  exit 1
}

docker exec -e ETCDCTL_API=3 "$node_container" etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  "$@"
