apiVersion: v1
kind: Pod
metadata:
  name: <INI_POD_NAME>
  labels:
    app: qserv
spec:
  dnsPolicy: Default
  hostNetwork: true
  subdomain: qserv
  containers:
    - name: mariadb
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
    # command: ["tail","-f", "/dev/null"]
      command: [<RESOURCE_START_MARIADB>]
      livenessProbe:
        tcpSocket:
          port: mariadb-port
        initialDelaySeconds: 15
        periodSeconds: 20
      readinessProbe:
        tcpSocket:
          port: mariadb-port
        initialDelaySeconds: 5
        periodSeconds: 10
      ports:
      - name: mariadb-port
        containerPort: 3306
      volumeMounts:
      - name: config-mariadb-etc
        mountPath: /config-mariadb-etc
      - name: config-mariadb-start
        mountPath: /config-start
    - name: xrootd
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      command: [<RESOURCE_START_WORKER>]
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
      livenessProbe:
        tcpSocket:
          port: wmgr-port
        initialDelaySeconds: 15
        periodSeconds: 20
      readinessProbe:
        tcpSocket:
          port: wmgr-port
        initialDelaySeconds: 5
        periodSeconds: 10
      ports:
      - name: wmgr-port
        containerPort: 5012
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
    - name: config-mariadb-configure
      configMap:
        name: config-mariadb-configure
    - name: config-mariadb-start
      configMap:
        name: config-mariadb-start
    - name: config-master
      configMap:
        name: config-master
    - name: config-mariadb-etc
      configMap:
        name: config-mariadb-etc
    - name: config-qserv-configure
      configMap:
        name: config-qserv-configure
    - name: config-worker-sql
      configMap:
        name: config-worker-sql
    - name: config-xrootd-etc
      configMap:
        name: config-xrootd-etc
    - name: config-xrootd-start
      configMap:
        name: config-xrootd-start
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
