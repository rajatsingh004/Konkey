# Lab: Kubernetes State and etcd

This exercise runs against the disposable kind cluster described in the repository root README. It focuses on observation and backup, not destructive recovery.

## 1. Create the cluster and sample objects

```sh
kind create cluster --name k8s-deepdive --config kind/cluster.yaml --wait 3m
kubectl apply -f lab/manifests/sample-workload.yaml
kubectl rollout status deployment/web-demo -n etcd-lab
```

Observe the API object version. Treat it as an opaque value; do not assume it is always numerically equal to the global etcd revision.

```sh
kubectl get deployment web-demo -n etcd-lab -o jsonpath='{.metadata.resourceVersion}{"\n"}'
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/kind-etcdctl.sh endpoint status -w table
```

## 2. Inspect Kubernetes key names

```sh
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/inspect-k8s-keys.sh
```

Expect paths beneath `/registry`, including namespace, ConfigMap, Pod, and Deployment records. The script only prints key names. Do not query or publish raw Secret values: Kubernetes data may be sensitive even when encoded.

## 3. Generate revision churn

```sh
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/create-churn.sh
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/kind-etcdctl.sh endpoint status -w table
```

Compare the reported revision before and after the create/delete loop. Compaction can remove historical versions but does not remove current Kubernetes objects.

## 4. Take and protect a snapshot

```sh
KIND_CLUSTER_NAME=k8s-deepdive sh scripts/backup-kind-etcd.sh
```

The snapshot and checksum are written to `./backups/`, which is ignored by Git. Verify snapshot metadata with `etcdutl snapshot status <snapshot>` using a version compatible with the etcd server. A backup is not proven until restore has been rehearsed separately.

## 5. Discuss recovery and maintenance

Read [etcd operations](../docs/etcd-operations.md). Explain why compaction and defragmentation solve different storage problems, why defragmentation should be performed one member at a time in HA, and what must be matched during a cluster restore.

## Cleanup

```sh
kind delete cluster --name k8s-deepdive
```
