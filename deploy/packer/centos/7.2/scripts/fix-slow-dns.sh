#!/bin/bash -eux

if [[ "${PACKER_BUILDER_TYPE}" =~ "virtualbox" ]]; then
  echo 'nameserver 8.8.8.8
nameserver 4.4.4.4
' > /etc/resolv.conf
  service network restart
fi
