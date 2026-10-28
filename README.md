# Kubernetes etcd Operations Lab

A hands-on Kubernetes control-plane lab for understanding how etcd stores Kubernetes state and practicing safe inspection, snapshot backup, compaction, and disaster-recovery planning.

This repository turns a guided learning session into a reproducible, disposable kind exercise. It does not claim production restore validation.

## What this demonstrates

- How etcd Raft quorum affects Kubernetes control-plane writes.
- How etcd MVCC revisions, Kubernetes object versions, and watch history relate.
- How to inspect Kubernetes registry key names without exposing stored object values.
- How to create and inspect an etcd snapshot.
- Why compaction and defragmentation are separate operations.
- How to plan a version-aware etcd restore.

## Repository layout

```text
.
├── README.md
├── .gitignore
├── kind/
│   └── cluster.yaml
├── lab/
│   ├── README.md
│   └── manifests/sample-workload.yaml
├── docs/
│   └── etcd-operations.md
└── scripts/
    ├── kind-etcdctl.sh
    ├── inspect-k8s-keys.sh
    ├── create-churn.sh
    └── backup-kind-etcd.sh
```

## Quick start

Requirements: Docker, kind, kubectl, and a POSIX shell.

```sh
kind create cluster --name k8s-deepdive --config kind/cluster.yaml --wait 3m
kubectl apply -f lab/manifests/sample-workload.yaml
kubectl get pods -n etcd-lab
```

Inspect etcd key names and save a local snapshot:

```sh
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/inspect-k8s-keys.sh
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/backup-kind-etcd.sh
```

Continue with the [lab exercise](lab/README.md) and [operations notes](docs/etcd-operations.md). Remove the local cluster when finished:

```sh
kind delete cluster --name k8s-deepdive
```

## Scope and safety

The kind cluster has one control-plane node and therefore one etcd member. It does not demonstrate quorum or production high availability. A three-member etcd cluster tolerates one member loss; if quorum is lost, new writes cannot be committed. Some Kubernetes reads may be served from caches, but the API is not guaranteed to remain read-only and available.

Kubernetes `resourceVersion` is an opaque API value. For etcd-backed resources it is associated with storage revisions, but numeric equality with the global etcd revision is not a stable API contract.

Do not run destructive compaction, defragmentation, or restore operations against production from this lab. Never commit etcd snapshots, Secret values, private keys, or credentials. Key names and metadata can also be sensitive.

## References

- [Kubernetes: Operating etcd clusters](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [etcd: Disaster recovery](https://etcd.io/docs/v3.7/op-guide/recovery/)
- [etcd: Maintenance](https://etcd.io/docs/v3.7/op-guide/maintenance/)
- [kind: Quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)
