#!/bin/sh

# Update Qserv configmaps 

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CONFIGMAP_DIR="${DIR}/configmap"
CZAR="czar-0"
REPL_CTL="repl-ctl"
REPL_DB="repl-db-0"
QSERV_DOMAIN="qserv"
CZAR_DN="${CZAR}.${QSERV_DOMAIN}"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options]

  Available options:
    -h          this message

  Update Qserv configmaps 

EOD
}

# get the options
while getopts h c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

echo "Create kubernetes configmaps for Qserv"

kubectl delete configmap --ignore-not-found=true config-domainnames
kubectl create configmap config-domainnames --from-literal=CZAR="$CZAR" \
    --from-literal=CZAR_DN="$CZAR_DN" \
    --from-literal=QSERV_DOMAIN="$QSERV_DOMAIN" \
    --from-literal=REPL_CTL="$REPL_CTL" \
    --from-literal=REPL_DB="$REPL_DB"

kubectl delete configmap --ignore-not-found=true config-dot-lsst
kubectl create configmap --from-file="$CONFIGMAP_DIR/dot-lsst" config-dot-lsst

kubectl delete configmap --ignore-not-found=true config-mariadb-configure
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/mariadb-configure.sh" config-mariadb-configure

kubectl delete configmap --ignore-not-found=true config-mariadb-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/start.sh" config-mariadb-start

kubectl delete configmap --ignore-not-found=true config-sql-czar
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/czar" config-sql-czar

kubectl delete configmap --ignore-not-found=true config-sql-repl
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/repl" config-sql-repl

kubectl delete configmap --ignore-not-found=true config-sql-worker
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/worker" config-sql-worker

kubectl delete configmap --ignore-not-found=true config-mariadb-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/etc" config-mariadb-etc

kubectl delete configmap --ignore-not-found=true config-proxy-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/etc" config-proxy-etc

kubectl delete configmap --ignore-not-found=true config-proxy-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/start.sh" config-proxy-start

kubectl delete configmap --ignore-not-found=true config-repl-db-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/repl-db/etc" config-repl-db-etc

kubectl delete configmap --ignore-not-found=true config-repl-db-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/repl-db/start.sh" config-repl-db-start

kubectl delete configmap --ignore-not-found=true config-repl-wrk-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/repl-wrk/etc" config-repl-wrk-etc

kubectl delete configmap --ignore-not-found=true config-repl-wrk-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/repl-wrk/start.sh" config-repl-wrk-start

kubectl delete configmap --ignore-not-found=true config-wmgr-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/wmgr/etc" config-wmgr-etc 

kubectl delete configmap --ignore-not-found=true config-wmgr-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/wmgr/start.sh" config-wmgr-start

kubectl delete configmap --ignore-not-found=true config-xrootd-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/xrootd/start.sh" config-xrootd-start

kubectl delete configmap --ignore-not-found=true config-xrootd-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/xrootd/etc" config-xrootd-etc

echo "Create kubernetes secrets for Qserv"
kubectl delete secret --ignore-not-found=true secret-wmgr
kubectl create secret generic secret-wmgr \
        --from-file="$CONFIGMAP_DIR/wmgr/wmgr.secret"

