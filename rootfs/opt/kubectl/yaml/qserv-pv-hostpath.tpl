apiVersion: v1
kind: PersistentVolume
metadata:
    name: <PV_NAME>
    labels:
        dataid: <DATA_ID>
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 100Gi
  hostPath:
    path: <DATA_PATH> 
