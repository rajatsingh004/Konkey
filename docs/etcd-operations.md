# etcd Operations Notes

## Raft and Kubernetes availability

etcd replicates writes through Raft. A write is committed after a majority of members acknowledges it. A three-member cluster can continue after one member fails; with only one of three members remaining, it cannot commit new writes. Kubernetes control-plane behavior during quorum loss is not simply “read-only”: writes that require etcd fail, while some reads may be served from API server caches. Availability depends on request type and component state.

An etcd cluster should use an odd number of members (commonly three or five), low-latency networking, and reliable storage. More members increase quorum cost and are not a substitute for sensible failure-domain placement.

## MVCC revisions and Kubernetes objects

etcd's MVCC store assigns monotonically increasing revisions to committed changes and retains historical key versions until compaction. Kubernetes objects expose `metadata.resourceVersion` as an opaque token used for concurrency and watch semantics. For objects stored in etcd, it is related to storage revisions, but clients must not depend on numeric equality with an etcd global revision.

Kubernetes stores objects under keys such as `/registry/pods/<namespace>/<name>`. Values use Kubernetes storage serialization (often protobuf in production). Do not inspect or share raw values casually: entries can include Secret data and other sensitive configuration.

## Compaction versus defragmentation

- **Compaction** removes historical MVCC revisions before a selected revision. A client asking for an already compacted revision receives a compacted-revision error. Retention policy must account for watchers that need history.
- **Defragmentation** rebuilds the backend database for one member and returns free pages to the filesystem. It is local to that member and temporarily blocks reads and writes there.

Compaction can make backend pages reusable without reducing the database file size. Defragmentation reclaims that file space. In a production HA cluster, compact according to the configured retention policy and defragment one member at a time while maintaining quorum and monitoring latency/health. These commands are intentionally not automated in this lab.

Inspect status and history in the local lab:

```sh
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/kind-etcdctl.sh endpoint status -w table
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/create-churn.sh
```

## Backup

The lab's `scripts/backup-kind-etcd.sh` takes an online snapshot with etcdctl, copies it out of the kind node, and writes a SHA-256 checksum. Use a compatible `etcdutl snapshot status` binary to inspect revision, hash, key count, and size. Store real backups encrypted and off-cluster, with access controls and tested retention. A snapshot contains the cluster's data and must be treated as sensitive.

## Restore planning

A restore is a full control-plane recovery event, not a routine rollback. Restore procedures vary by Kubernetes distribution and etcd version. Before production recovery, confirm:

1. Snapshot integrity, source cluster, snapshot time, and version compatibility.
2. How to stop API servers and etcd safely for the distribution.
3. The restored data directory, member names, peer URLs, initial-cluster map, certificates, ownership, and static pod/service configuration.
4. For etcd versions supporting them, whether Kubernetes watch caches require a revision bump and `--mark-compacted` during restore. Follow the version-specific upstream guidance rather than copying flags blindly.
5. A rehearsed recovery, API health checks, node/workload reconciliation, and a documented recovery point objective.

For kubeadm environments, follow the Kubernetes etcd operations guide and the upstream etcd recovery guide. Never perform an experimental restore against a live cluster.
