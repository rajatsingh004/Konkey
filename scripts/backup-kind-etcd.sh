#!/usr/bin/env sh
# Take a consistent live etcd snapshot from the local kind control plane.
set -eu
umask 077

cluster_name=${KIND_CLUSTER_NAME:-k8s-deepdive}
node_container="${cluster_name}-control-plane"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir=${BACKUP_DIR:-./backups}
snapshot_name="etcd-${cluster_name}-${timestamp}.db"
container_snapshot="/tmp/$snapshot_name"

docker inspect "$node_container" >/dev/null 2>&1 || {
  echo "kind node container not found: $node_container" >&2
  exit 1
}
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"

docker exec -e ETCDCTL_API=3 "$node_container" etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  snapshot save "$container_snapshot"

docker cp "$node_container:$container_snapshot" "$backup_dir/$snapshot_name"
docker exec "$node_container" rm -f "$container_snapshot"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$backup_dir/$snapshot_name" > "$backup_dir/$snapshot_name.sha256"
else
  shasum -a 256 "$backup_dir/$snapshot_name" > "$backup_dir/$snapshot_name.sha256"
fi

echo "Snapshot: $backup_dir/$snapshot_name"
echo "Checksum: $backup_dir/$snapshot_name.sha256"
echo "Inspect snapshot metadata with a version-compatible etcdutl snapshot status command."
echo "Keep this local backup out of Git and copy production backups to protected off-cluster storage."
