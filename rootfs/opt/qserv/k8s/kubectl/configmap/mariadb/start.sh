# Start mariadb inside pod
# and do not exit

# @author  Fabrice Jammes, IN2P3/SLAC

set -e

# Source pathes to eups packages
. /qserv/run/etc/sysconfig/qserv

MARIADB_CONF="/config-etc/my.cnf"
if [ -e "$MARIADB_CONF" ]; then
    ln -sf "$MARIADB_CONF" /etc/my.cnf
fi

echo "-- Start mariadb server."
mysqld || echo "ERROR: Fail to start MariaDB"
