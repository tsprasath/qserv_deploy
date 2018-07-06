apiVersion: v1
kind: Pod
metadata:
  labels:
    app: qserv
    node: worker
  name: <INI_POD_NAME>
spec:
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
      - mountPath: /secret
        name: secret-wmgr
    - name: proxy
      command:
      - sh
      - /config-start/start.sh
      image: "<INI_IMAGE>"
      imagePullPolicy: Always
      livenessProbe:
        exec:
          command:
            - /bin/bash
            - /config-probe/probe.sh
        initialDelaySeconds: 15
        periodSeconds: 20
      readinessProbe:
        exec:
          command:
            - /bin/bash
            - /config-probe/probe.sh
        initialDelaySeconds: 5
        periodSeconds: 10
      ports:
      - name: proxy-port
        containerPort: 4040
      volumeMounts:
      - mountPath: /home/qserv/.lsst
        name: config-dot-lsst
      - mountPath: /config-start
        name: config-proxy-start
      - mountPath: /config-etc
        name: config-proxy-etc
      - mountPath: /config-probe
        name: config-proxy-probe
      - mountPath: /secret
        name: secret-wmgr
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
    - name: config-sql
      configMap:
        name: config-sql
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
    - name: config-dot-lsst
      configMap:
        name: config-dot-lsst
    - name: config-proxy-start
      configMap:
        name: config-proxy-start
        defaultMode: 0755
    - name: config-proxy-etc
      configMap:
        name: config-proxy-etc
    - name: config-proxy-probe
      configMap:
        name: config-proxy-probe
    - name: secret-wmgr
      secret:
        secretName: secret-wmgr
  restartPolicy: Never
