#!/bin/bash
for i in {1..5}
do
   echo "TEST TEST TEST NUMBER $i TEST TEST TEST"
   echo "======================================="
   ./provision-install-test.sh -k
   echo "======================================="
done
