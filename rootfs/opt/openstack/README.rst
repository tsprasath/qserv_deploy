**************************************
Provision Qserv using Docker+Openstack
**************************************
This is the python client setup, to use the Terraform setup see `this README <terraform/README.md>`_

Pre-requisite
-------------

* Install system dependencies

.. code-block:: bash

   sudo apt-get install python-dev python-pip

   # Might be required on Ubuntu 14.04
   pip install --upgrade --force pbr

   # Install the OpenStack client
   sudo pip install shade==1.27.1

   # Install docker and gnu-parallel
   sudo apt-get install docker parallel

* Download Openstack RC file: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/5/html/End_User_Guide/cli_openrc.html#openrc-dashboard

* Add your user to docker group


Provision Qserv & run multinode tests
-------------------------------------

* Clone Qserv repository and set Openstack environment and parameters:

.. code-block:: bash

   SRC_DIR=${HOME}/src
   mkdir ${SRC_DIR}
   cd ${SRC_DIR}
   git clone https://github.com/lsst/qserv_deploy.git
   cd qserv_deploy/openstack

   # Source Openstack RC file
   # This is an example for NCSA
   . ./LSST-openrc.sh

   # Update the configuration file which contains instance parameters
   # Add special tuning if needed
   cp LSST.example.conf "${OS_PROJECT_NAME}.conf"

* Create customized image, provision openstack cluster and run integration tests

.. code-block:: bash

    # Use -h to see all available options
    ./provision-install-test.sh

