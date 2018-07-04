apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: <PVC_NAME>
spec:
    accessModes:
      - ReadWriteOnce
    volumeMode: Filesystem
    resources:
        requests:
            storage: 10Gi
    storageClassName: qserv-local-storage
    selector:
        matchLabels:
            dataid: <DATA_ID>
