#!/bin/bash
#set -x

firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=3000/tcp
firewall-cmd --reload

export use_shared_storage='${use_shared_storage}'

if [[ $use_shared_storage == "true" ]]; then
  setenforce 0 # disabling SELinux (otherwise zeppelin service will not start).
  sed -i.bak 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config # SELinux disabled.
fi

echo "Local Security Granted !"
