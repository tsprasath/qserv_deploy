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
            storage: 100Gi # Mandatory, must be the same in PV
    storageClassName: qserv-local-storage
    selector:
        matchLabels:
            dataid: <DATA_ID>
