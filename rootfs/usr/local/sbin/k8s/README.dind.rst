.. code-block:: bash

   # Install docker v1.12:
   sudo apt-get install docker-engine="1.12.1-*"

   # Start dind cluster
   ./install-k8s.sh

   # Configure k8s
   ./configure-k8s.sh

   # Then run runkubectl.sh and qserv startup scripts...
   ./run-kubectl.sh /root/admin/run-multinode-tests.sh
