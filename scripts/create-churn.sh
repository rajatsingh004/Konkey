#!/usr/bin/env sh
# Create/delete ConfigMaps to generate etcd revisions in the disposable lab.
set -eu

namespace=${NAMESPACE:-etcd-lab}
count=${COUNT:-25}
prefix="revision-demo-$(date +%s)"

case "$count" in
  ''|*[!0-9]*) echo "COUNT must be a positive integer" >&2; exit 2 ;;
esac
[ "$count" -gt 0 ] || { echo "COUNT must be greater than zero" >&2; exit 2; }

kubectl get namespace "$namespace" >/dev/null
echo "Creating and deleting $count ConfigMaps in namespace $namespace"
i=1
while [ "$i" -le "$count" ]; do
  name="$prefix-$i"
  kubectl create configmap "$name" -n "$namespace" --from-literal=iteration="$i" >/dev/null
  kubectl delete configmap "$name" -n "$namespace" --wait=true >/dev/null
  i=$((i + 1))
done
echo "Done. Check etcd endpoint status for the advanced revision."
