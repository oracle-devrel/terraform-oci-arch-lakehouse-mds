#!/bin/bash
#set -x

##### FSS-compatible code

export use_shared_storage='${use_shared_storage}'

if [[ $use_shared_storage == "true" ]]; then
  echo "Mount NFS share: ${shared_working_dir}"
  yum install -y -q nfs-utils
  mkdir -p ${shared_working_dir}
  echo '${mt_ip_address}:${shared_working_dir} ${shared_working_dir} nfs nosharecache,context="system_u:object_r:httpd_sys_rw_content_t:s0" 0 0' >> /etc/fstab
  setsebool -P httpd_use_nfs=1
  mount ${shared_working_dir}
  mount
  echo "NFS share mounted."
  cd ${shared_working_dir}
else
  echo "No mount NFS share. Moving to /opt" 
  cd /opt	
fi

wget https://dlcdn.apache.org/zeppelin/zeppelin-0.10.0/zeppelin-0.10.0-bin-all.tgz

if [[ $use_shared_storage == "true" ]]; then
  tar zxvf zeppelin-0.10.0-bin-all.tgz --directory ${shared_working_dir}
  rm -f zeppelin-0.10.0-bin-all.tgz
  mv ${shared_working_dir}/zeppelin-0.10.0-bin-all ${shared_working_dir}/zeppelin
  cd ${shared_working_dir}/zeppelin
else
  tar zxvf zeppelin-0.10.0-bin-all.tgz
  rm -f zeppelin-0.10.0-bin-all.tgz
  mv zeppelin-0.10.0-bin-all zeppelin
  cd zeppelin
fi 

cp conf/zeppelin-site.xml.template conf/zeppelin-site.xml

sed -i 's/127.0.0.1/0.0.0.0/' conf/zeppelin-site.xml
sed -i 's/8080/80/' conf/zeppelin-site.xml
sed -i 's/8443/443/' conf/zeppelin-site.xml

dnf install -y mysql-connector-java mysql-connector-python3
mkdir interpreter/mysql
cp /usr/share/java/mysql-connector-java.jar interpreter/mysql

./bin/zeppelin-systemd-service.sh enable
mv /etc/systemd/system/zeppelin.systemd /etc/systemd/system/zeppelin.service
/usr/bin/systemctl daemon-reload

systemctl start zeppelin

echo "Zeppelin installed and started !"

##### Grafana code

echo "[grafana]" >> /etc/yum.repos.d/grafana.repo
echo "name=grafana" >> /etc/yum.repos.d/grafana.repo
echo "baseurl=https://packages.grafana.com/oss/rpm" >> /etc/yum.repos.d/grafana.repo
echo "repo_gpgcheck=1" >> /etc/yum.repos.d/grafana.repo
echo "enabled=1" >> /etc/yum.repos.d/grafana.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/grafana.repo
echo "gpgkey=https://packages.grafana.com/gpg.key" >> /etc/yum.repos.d/grafana.repo
echo "sslverify=1" >> /etc/yum.repos.d/grafana.repo
echo "sslcacert=/etc/pki/tls/certs/ca-bundle.crt" >> /etc/yum.repos.d/grafana.repo

sudo yum install -y grafana

if [[ $use_shared_storage == "true" ]]; then
  cd ${shared_working_dir}
  mkdir grafana grafana/plugins
  sed -i 's/\;data = \/var\/lib\/grafana/data = \${shared_working_dir}\/grafana/g' /etc/grafana/grafana.ini
  #sed -i 's/\;logs = \/var\/log\/grafana/logs = \${shared_working_dir}\/grafana\/log/g' grafana.ini
  sed -i 's/\;plugins = \/var\/lib\/grafana\/plugins/plugins = \${shared_working_dir}\/grafana\/plugins/g' /etc/grafana/grafana.ini
fi

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server --no-pager

# Configure the Grafana server to start at boot
sudo systemctl enable grafana-server

echo "Grafana installed and started !"

# Path to where grafana can store temp files, sessions, and the sqlite3 db (if that is used)
#;data = /var/lib/grafana

# Temporary files in `data` directory older than given duration will be removed
#;temp_data_lifetime = 24h

# Directory where grafana can store logs
#;logs = /var/log/grafana

# Directory where grafana will automatically scan and look for plugins
#;plugins = /var/lib/grafana/plugins


