source variables

create-manmon-conf-rpm-dirs() {
  mkdir -p ${DATA_DIR}/manmon-conf
  chown 10010 ${DATA_DIR}/manmon-conf
  chmod 700 ${DATA_DIR}/manmon-conf
  rm -rf ${DATA_DIR}/manmon-conf-rpm/rpmbuild/SOURCES
  mkdir -p ${DATA_DIR}/manmon-conf-rpm/rpmbuild/SOURCES
  cp ${DATA_DIR}/manmon-certs/.certs/client1.crt  ${DATA_DIR}/manmon-conf-rpm/rpmbuild/SOURCES/.manmon_crt
  cp ${DATA_DIR}/manmon-certs/.certs/client1.key  ${DATA_DIR}/manmon-conf-rpm/rpmbuild/SOURCES/.manmon_key
  cp ${DATA_DIR}/manmon-certs/.certs/ca.crt  ${DATA_DIR}/manmon-conf-rpm/rpmbuild/SOURCES/.manmon_ca
  chown -R 10010 ${DATA_DIR}/manmon-conf-rpm/rpmbuild
  chmod -R 700 ${DATA_DIR}/manmon-conf-rpm/rpmbuild
}


create-manmon-conf-dpkg-dirs() {  
  mkdir -p ${DATA_DIR}/manmon-conf
  chown 10010 ${DATA_DIR}/manmon-conf
  chmod 700 ${DATA_DIR}/manmon-conf
  rm -rf ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib/manmon
  mkdir -p ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib/manmon
  cp ${DATA_DIR}/manmon-certs/.certs/client1.crt  ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_crt
  cp ${DATA_DIR}/manmon-certs/.certs/client1.key  ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_key
  cp ${DATA_DIR}/manmon-certs/.certs/ca.crt  ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_ca
  chown -R 10010 ${DATA_DIR}/manmon-conf-dpkg/.tmp
  chmod 700 ${DATA_DIR}/manmon-conf-dpkg/
  chmod 700 ${DATA_DIR}/manmon-conf-dpkg/.tmp
  chmod 700 ${DATA_DIR}/manmon-conf-dpkg/.tmp/var
  chmod 700 ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib
  chmod 700 ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib/manmon
  chmod 400 ${DATA_DIR}/manmon-conf-dpkg/.tmp/var/lib/manmon/.manmon_*
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
  mkdir -p ${DATA_DIR}/manmon-uploader-db/
  chmod 700 ${DATA_DIR}/manmon-uploader-db/
  chown 10007 ${DATA_DIR}/manmon-uploader-db/
}

create-manmon-auth-db-dirs() {
  mkdir -p ${DATA_DIR}/manmon-auth-db/
  chmod 700 ${DATA_DIR}/manmon-auth-db/
  chown 10005 ${DATA_DIR}/manmon-auth-db/
}

create-manmon-auth-dirs() {

  mkdir -p ${DATA_DIR}/manmon-auth/webapps
  mkdir -p ${DATA_DIR}/manmon-auth/logs
  chmod 700 ${DATA_DIR}/manmon-auth/
  chown 10004 ${DATA_DIR}/manmon-auth
  chmod 700 ${DATA_DIR}/manmon-auth/webapps
  chown 10004 ${DATA_DIR}/manmon-auth/webapps
  chown 10004 ${DATA_DIR}/manmon-auth/logs
  chmod 700 ${DATA_DIR}/manmon-auth/logs
}

create-certs-dirs() {
  mkdir -p ${DATA_DIR}/manmon-certs/conf
  mkdir -p ${DATA_DIR}/manmon-certs/.certs
  chown 10008 ${DATA_DIR}/manmon-certs/conf
  chown 10008 ${DATA_DIR}/manmon-certs/.certs
  chmod 700 ${DATA_DIR}/manmon-certs/conf
  chmod 700 ${DATA_DIR}/manmon-certs/.certs
  chown 10008 ${DATA_DIR}/manmon-certs
  chmod 700 ${DATA_DIR}/manmon-certs
  mkdir -p ${DATA_DIR}/manmon-conf
  chown 10008 ${DATA_DIR}/manmon-conf
  chmod 700 ${DATA_DIR}/manmon-conf
  chown 10008 ${DATA_DIR}/manmon-certs
  chmod 700 ${DATA_DIR}/manmon-certs
}


create-kafka-dirs() {
  mkdir -p ${DATA_DIR}/manmon-kafka/data/
  chown 10003 ${DATA_DIR}/manmon-kafka
  mkdir -p ${DATA_DIR}/manmon-kafka/logs
  chown 10003 ${DATA_DIR}/manmon-kafka/data
  chown 10003 ${DATA_DIR}/manmon-kafka/logs
  chmod 700 ${DATA_DIR}/manmon-kafka
  chmod 700 ${DATA_DIR}/manmon-kafka/data
  chmod 700 ${DATA_DIR}/manmon-kafka/logs
}

create-zookeeper-dirs() {
  mkdir -p ${DATA_DIR}/manmon-zookeeper/data/
  mkdir -p ${DATA_DIR}/manmon-zookeeper/logs/
  chown 10002 ${DATA_DIR}/manmon-zookeeper
  chown 10002 ${DATA_DIR}/manmon-zookeeper/data
  chown 10002 ${DATA_DIR}/manmon-zookeeper/logs
  chmod 700 ${DATA_DIR}/manmon-zookeeper
  chmod 700 ${DATA_DIR}/manmon-zookeeper/data
  chmod 700 ${DATA_DIR}/manmon-zookeeper/logs
}

create-uploader-dirs-and-copy-keys() {
  mkdir -p ${DATA_DIR}/manmon-uploader/.auth
  mkdir -p ${DATA_DIR}/manmon-uploader/conf
  mkdir -p ${DATA_DIR}/manmon-uploader/webapps
  mkdir -p ${DATA_DIR}/manmon-uploader/logs
  chmod 700 ${DATA_DIR}/manmon-uploader/.auth
  chmod 700 ${DATA_DIR}/manmon-uploader
  chmod 700 ${DATA_DIR}/manmon-uploader/conf
  chmod 700 ${DATA_DIR}/manmon-uploader/webapps
  chmod 700 ${DATA_DIR}/manmon-uploader/logs
  chown 10006 ${DATA_DIR}/manmon-uploader/.auth
  chown 10006 ${DATA_DIR}/manmon-uploader/conf
  chown 10006 ${DATA_DIR}/manmon-uploader
  chown 10006 ${DATA_DIR}/manmon-uploader/webapps
  chown 10006 ${DATA_DIR}/manmon-uploader/logs

  if [ ! -f ${DATA_DIR}/manmon-uploader/.auth/.cacerts.jks ]
  then
    cp -p ${DATA_DIR}/manmon-conf/.tomcat_constants ${DATA_DIR}/manmon-uploader/.auth/.tomcat_constants
    cp -p ${DATA_DIR}/manmon-certs/.certs/mycert.p12 ${DATA_DIR}/manmon-uploader/.auth/.mycert.p12
    cp -p ${DATA_DIR}/manmon-certs/.certs/cacerts.jks ${DATA_DIR}/manmon-uploader/.auth/.cacerts.jks
    chown 10006 ${DATA_DIR}/manmon-uploader/.auth/.mycert.p12
    chown 10006 ${DATA_DIR}/manmon-uploader/.auth/.cacerts.jks
    chmod 400 ${DATA_DIR}/manmon-uploader/.auth/.mycert.p12
    chmod 400 ${DATA_DIR}/manmon-uploader/.auth/.cacerts.jks
    chown 10006 ${DATA_DIR}/manmon-uploader/.auth/.tomcat_constants
    chmod 400 ${DATA_DIR}/manmon-uploader/.auth/.tomcat_constants
    
    cp -p ${DATA_DIR}/manmon-certs/.certs/uploader-server.xml ${DATA_DIR}/manmon-uploader/conf/server.xml
    chown 10006 ${DATA_DIR}/manmon-uploader/conf/server.xml
    chmod 400 ${DATA_DIR}/manmon-uploader/conf/server.xml
  fi
}
