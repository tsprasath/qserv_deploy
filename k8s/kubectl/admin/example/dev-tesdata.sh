# Example script used to develop inside kubernetes
#
su - qserv
git clone https://github.com/lsst/qserv_testdata.git
. /qserv/stack/loadLSST.bash
setup qserv_distrib -t qserv-dev
setup -k -r qserv_testdata/ 
cd qserv_testdata/
scons
which qserv-check-integration.py
echo "CREATE NODE worker1 type=worker port=5012 host=qserv-worker-1; CREATE NODE
worker2 type=worker port=5012 host=qserv-worker-2; CREATE NODE worker3
type=worker port=5012 host=qserv-worker-3;" | \
    qserv-admin.py -c mysql://qsmaster@127.0.0.1:3306/qservCssData
qserv-check-integration.py --case=01 --load -V DEBUG
