apiVersion: v1
kind: Pod
metadata:
  name: <INI_POD_NAME>
  labels:
    app: qserv
    node: master
spec:
  dnsPolicy: Default
  hostNetwork: true
  subdomain: qserv
  containers:
    - name: mariadb
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      command: [<RESOURCE_START_MARIADB>]
      volumeMounts:
      - name: config-my-dot-cnf
        mountPath: /config-mariadb
      - name: config-mariadb-start
        mountPath: /config-start
    - name: xrootd
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      command: [<RESOURCE_START_MASTER>]
      env:
      - name: QSERV_MASTER
        valueFrom:
          configMapKeyRef:
            name: config-master
            key: qserv_master
      securityContext:
        capabilities:
          add:
          - IPC_LOCK
      volumeMounts:
      - name: config-xrootd-etc
        mountPath: /config-etc
      - name: config-xrootd-start
        mountPath: /config-start
    - name: proxy
      command:
      - sh
      - /config-start/start.sh
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      volumeMounts:
      - mountPath: /home/qserv/.lsst
        name: config-dot-lsst
      - mountPath: /config-start
        name: config-proxy-start
      - mountPath: /config-etc
        name: config-proxy-etc
      - mountPath: /qserv/run/tmp
        name: tmp-volume
      - mountPath: /qserv/data
        name: data-volume
      - mountPath: /qserv/run
        name: run-volume
      - mountPath: /secret
        name: secret-wmgr
    - name: wmgr
      command:
        - sh
        - /config-start/start.sh
      env:
        - name: QSERV_MASTER
          valueFrom:
            configMapKeyRef:
              name: config-master
              key: qserv_master
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      volumeMounts:
      - mountPath: /config-start
        name: config-wmgr-start
      - mountPath: /config-etc
        name: config-wmgr-etc
      - mountPath: /qserv/run/tmp
        name: tmp-volume
      - mountPath: /qserv/data
        name: data-volume
      - mountPath: /secret
        name: secret-wmgr
  nodeSelector:
    kubernetes.io/hostname: <INI_HOST>
  volumes:
    - name: config-dot-lsst
      configMap:
        name: config-dot-lsst
    - name: config-mariadb-configure
      configMap:
        name: config-mariadb-configure
    - name: config-mariadb-start
      configMap:
        name: config-mariadb-start
    - name: config-master-sql
      configMap:
        name: config-master-sql
    - name: config-xrootd-etc
      configMap:
        name: config-xrootd-etc
    - name: config-xrootd-start
      configMap:
        name: config-xrootd-start
    - name: config-master
      configMap:
        name: config-master
    - name: config-my-dot-cnf
      configMap:
        name: config-my-dot-cnf
    - name: config-proxy-etc
      configMap:
        name: config-proxy-etc
    - name: config-proxy-start
      configMap:
        name: config-proxy-start
    - name: config-qserv-configure
      configMap:
        name: config-qserv-configure
    - name: config-wmgr-etc
      configMap:
        name: config-wmgr-etc
    - name: config-wmgr-start
      configMap:
        name: config-wmgr-start
    - name: secret-wmgr
      secret:
        secretName: secret-wmgr
  restartPolicy: Never
