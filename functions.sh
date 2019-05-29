

create-manmon-conf-rpm-dirs() {
  mkdir -p /home/manmon-data/manmon-conf
  chown 10010 /home/manmon-data/manmon-conf
  chmod 700 /home/manmon-data/manmon-conf
  rm -rf /home/manmon-data/manmon-conf-rpm/rpmbuild/SOURCES
  mkdir -p /home/manmon-data/manmon-conf-rpm/rpmbuild/SOURCES
  cp /home/manmon-data/manmon-certs/.certs/client1.crt  /home/manmon-data/manmon-conf-rpm/rpmbuild/SOURCES/.manmon_crt
  cp /home/manmon-data/manmon-certs/.certs/client1.key  /home/manmon-data/manmon-conf-rpm/rpmbuild/SOURCES/.manmon_key
  cp /home/manmon-data/manmon-certs/.certs/ca.crt  /home/manmon-data/manmon-conf-rpm/rpmbuild/SOURCES/.manmon_ca
  chown -R 10010 /home/manmon-data/manmon-conf-rpm/rpmbuild
  chmod -R 700 /home/manmon-data/manmon-conf-rpm/rpmbuild
}


create-manmon-conf-dpkg-dirs() {  
  mkdir -p /home/manmon-data/manmon-conf
  chown 10010 /home/manmon-data/manmon-conf
  chmod 700 /home/manmon-data/manmon-conf
  rm -rf /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib/manmon
  mkdir -p /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib/manmon
  cp /home/manmon-data/manmon-certs/.certs/client1.crt  /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_crt
  cp /home/manmon-data/manmon-certs/.certs/client1.key  /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_key
  cp /home/manmon-data/manmon-certs/.certs/ca.crt  /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_ca
  chown -R 10010 /home/manmon-data/manmon-conf-dpkg/.tmp
  chmod 700 /home/manmon-data/manmon-conf-dpkg/
  chmod 700 /home/manmon-data/manmon-conf-dpkg/.tmp
  chmod 700 /home/manmon-data/manmon-conf-dpkg/.tmp/var
  chmod 700 /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib
  chmod 700 /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib/manmon
  chmod 400 /home/manmon-data/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_*
}

add-users() {
  useradd -M -N -u 10002 manmon_zk
  useradd -M -N -u 10003 manmon_kafka
  useradd -M -N -u 10004 manmon_auth
  useradd -M -N -u 10005 manmon_auth_db
  useradd -M -N -u 10006 manmon_uploader
  useradd -M -N -u 10007 manmon_uploader_db
  useradd -M -N -u 10008 manmon_certs
  useradd -M -N -u 10009 manmon_conf
  useradd -M -N -u 10010 mmagent
}

create-manmon-upload-db-dirs() {
  mkdir -p /home/manmon-data/manmon-uploader-db/
  chmod 700 /home/manmon-data/manmon-uploader-db/
  chown 10007 /home/manmon-data/manmon-uploader-db/
}

create-manmon-auth-db-dirs() {
  mkdir -p /home/manmon-data/manmon-auth-db/
  chmod 700 /home/manmon-data/manmon-auth-db/
  chown 10005 /home/manmon-data/manmon-auth-db/
}

create-manmon-auth-dirs() {

  mkdir -p /home/manmon-data/manmon-auth/webapps
  mkdir -p /home/manmon-data/manmon-auth/logs
  chmod 700 /home/manmon-data/manmon-auth/
  chown 10004 /home/manmon-data/manmon-auth
  chmod 700 /home/manmon-data/manmon-auth/webapps
  chown 10004 /home/manmon-data/manmon-auth/webapps
  chown 10004 /home/manmon-data/manmon-auth/logs
  chmod 700 /home/manmon-data/manmon-auth/logs
}

create-certs-dirs() {
  mkdir -p /home/manmon-data/manmon-certs/conf
  mkdir -p /home/manmon-data/manmon-certs/.certs
  chown 10008 /home/manmon-data/manmon-certs/conf
  chown 10008 /home/manmon-data/manmon-certs/.certs
  chmod 700 /home/manmon-data/manmon-certs/conf
  chmod 700 /home/manmon-data/manmon-certs/.certs
  chown 10008 /home/manmon-data/manmon-certs
  chmod 700 /home/manmon-data/manmon-certs
  mkdir -p /home/manmon-data/manmon-conf
  chown 10008 /home/manmon-data/manmon-conf
  chmod 700 /home/manmon-data/manmon-conf
  chown 10008 /home/manmon-data/manmon-certs
  chmod 700 /home/manmon-data/manmon-certs
}


create-kafka-dirs() {
  mkdir -p /home/manmon-data/manmon-kafka/data/
  chown 10003 /home/manmon-data/manmon-kafka
  mkdir -p /home/manmon-data/manmon-kafka/logs
  chown 10003 /home/manmon-data/manmon-kafka/data
  chown 10003 /home/manmon-data/manmon-kafka/logs
  chmod 700 /home/manmon-data/manmon-kafka
  chmod 700 /home/manmon-data/manmon-kafka/data
  chmod 700 /home/manmon-data/manmon-kafka/logs
}

create-zookeeper-dirs() {
  mkdir -p /home/manmon-data/manmon-zookeeper/data/
  mkdir -p /home/manmon-data/manmon-zookeeper/logs/
  chown 10002 /home/manmon-data/manmon-zookeeper
  chown 10002 /home/manmon-data/manmon-zookeeper/data
  chown 10002 /home/manmon-data/manmon-zookeeper/logs
  chmod 700 /home/manmon-data/manmon-zookeeper
  chmod 700 /home/manmon-data/manmon-zookeeper/data
  chmod 700 /home/manmon-data/manmon-zookeeper/logs
}

create-uploader-dirs-and-copy-keys() {
  mkdir -p /home/manmon-data/manmon-uploader/.auth
  mkdir -p /home/manmon-data/manmon-uploader/conf
  mkdir -p /home/manmon-data/manmon-uploader/webapps
  mkdir -p /home/manmon-data/manmon-uploader/logs
  chmod 700 /home/manmon-data/manmon-uploader/.auth
  chmod 700 /home/manmon-data/manmon-uploader
  chmod 700 /home/manmon-data/manmon-uploader/conf
  chmod 700 /home/manmon-data/manmon-uploader/webapps
  chmod 700 /home/manmon-data/manmon-uploader/logs
  chown 10006 /home/manmon-data/manmon-uploader/.auth
  chown 10006 /home/manmon-data/manmon-uploader/conf
  chown 10006 /home/manmon-data/manmon-uploader
  chown 10006 /home/manmon-data/manmon-uploader/webapps
  chown 10006 /home/manmon-data/manmon-uploader/logs

  if [ ! -f /home/manmon-data/manmon-uploader/.auth/.cacerts.jks ]
  then
    cp -p /home/manmon-data/manmon-conf/.tomcat_constants /home/manmon-data/manmon-uploader/.auth/.tomcat_constants
    cp -p /home/manmon-data/manmon-certs/.certs/mycert.p12 /home/manmon-data/manmon-uploader/.auth/.mycert.p12
    cp -p /home/manmon-data/manmon-certs/.certs/cacerts.jks /home/manmon-data/manmon-uploader/.auth/.cacerts.jks
    chown 10006 /home/manmon-data/manmon-uploader/.auth/.mycert.p12
    chown 10006 /home/manmon-data/manmon-uploader/.auth/.cacerts.jks
    chmod 400 /home/manmon-data/manmon-uploader/.auth/.mycert.p12
    chmod 400 /home/manmon-data/manmon-uploader/.auth/.cacerts.jks
    chown 10006 /home/manmon-data/manmon-uploader/.auth/.tomcat_constants
    chmod 400 /home/manmon-data/manmon-uploader/.auth/.tomcat_constants
    
    cp -p /home/manmon-data/manmon-certs/.certs/uploader-server.xml /home/manmon-data/manmon-uploader/conf/server.xml
    chown 10006 /home/manmon-data/manmon-uploader/conf/server.xml
    chmod 400 /home/manmon-data/manmon-uploader/conf/server.xml
  fi
}
