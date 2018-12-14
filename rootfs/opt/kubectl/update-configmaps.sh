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

kubectl delete configmap --ignore-not-found=true config-sql-czar
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/czar" config-sql-czar

kubectl delete configmap --ignore-not-found=true config-sql-repl
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/repl" config-sql-repl

kubectl delete configmap --ignore-not-found=true config-sql-worker
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/worker" config-sql-worker

SERVICES="mariadb proxy repl-ctl repl-db repl-wrk wmgr xrootd"

for service in $SERVICES
do
    kubectl delete configmap --ignore-not-found=true config-${service}-etc
    kubectl create configmap --from-file="$CONFIGMAP_DIR/$service/etc" config-${service}-etc

    kubectl delete configmap --ignore-not-found=true config-${service}-start
    kubectl create configmap --from-file="$CONFIGMAP_DIR/$service/start.sh" config-${service}-start
done

echo "Create kubernetes secrets for Qserv"
kubectl delete secret --ignore-not-found=true secret-wmgr
kubectl create secret generic secret-wmgr \
        --from-file="$CONFIGMAP_DIR/wmgr/wmgr.secret"

