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
    - name: master
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      command: [<RESOURCE_START_MASTER>]
      env:
      - name: NODE_TYPE
        value: master
      securityContext:
        capabilities:
          add:
          - IPC_LOCK
      volumeMounts:
      - name: config-xrootd-start
        mountPath: /config-start
    - name: myproxy
      command:
      - sh
      - /config-start/start.sh
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      volumeMounts:
      - mountPath: /home/qserv/.lsst
        name: config-dot-lsst
      - mountPath: /config-start
        name: config-myproxy-start
      - mountPath: /config-etc
        name: config-myproxy-etc
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
              name: config-wmgr-etc
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
    - name: config-xrootd-start
      configMap:
        name: config-xrootd-start
    - name: config-my-dot-cnf
      configMap:
        name: config-my-dot-cnf
    - name: config-myproxy-etc
      configMap:
        name: config-myproxy-etc
    - name: config-myproxy-start
      configMap:
        name: config-myproxy-start
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
