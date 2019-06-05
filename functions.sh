source variables

SELINUXENABLED=false
if [ ! -f /usr/bin/wget ]
then
  echo "Need wget"
  exit 1
fi
if [ -z "$DATA_DIR" ]
then
  echo "Need variable DATA_DIR"
  exit 1
fi
if [ -z "$UPLOADHOST" ]
then
  echo "Need variable UPLOADHOST"
  exit 1
fi
if [ -z "$CONF_NAME" ]
then
  echo "Need variable CONF_NAME"
  exit 1
fi
if [ -z "$NETWORK_SIZE" ]
then
  echo "Need variable NETWORK_SIZE"
  exit 1
fi
if [ -z "$IP_PREFIX" ]
then
  echo "Need variable IP_PREFIX"
  exit 1
fi
if [ `docker network list -q -f "name=manmon"|wc -l` -eq 1 ]
then
  echo "Docker manmon network exists already - not creating"
else
  docker network create --driver=bridge --subnet=${IP_PREFIX}.0/$NETWORK_SIZE manmon 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating docker manmon network"
    exit 1
  else
    echo "Created Docker manmon network"
  fi
fi

if [ -f /usr/sbin/selinuxenabled ]
then
  if /usr/sbin/selinuxenabled
  then
    SELINUXENABLED=true
  fi
fi


download-war() {
   DLAPP="$1"
   echo "Downloading WAR for ${DLAPP}"
   wget -q -O "${DATA_DIR}/manmon-${DLAPP}.war" "${WAR_LOCATION}/manmon-${DLAPP}.war"
   mv "${DATA_DIR}/manmon-${DLAPP}.war" "${DATA_DIR}/manmon_${DLAPP}/webapps/manmon-${DLAPP}.war"
   if [ "$?" -ne 0 ]
   then
     echo "Error downloading WAR for ${DLAPP}"
     exit 1
   fi
   if $SELINUXENABLED
   then
     chcon -Rt svirt_sandbox_file_t "${DATA_DIR}/manmon_${DLAPP}/webapps/manmon-${DLAPP}.war"
   fi
}


create-manmon-dirs() {
  DIRAPP="$1"
  echo "Creating directories for ${DIRAPP}"
  mkdir -p ${DATA_DIR}/manmon_${DIRAPP}/webapps
  mkdir -p ${DATA_DIR}/manmon_${DIRAPP}/logs
  chmod 700 ${DATA_DIR}/manmon_${DIRAPP}/
  chown manmon_${DIRAPP} ${DATA_DIR}/manmon_${DIRAPP}
  chmod 700 ${DATA_DIR}/manmon_${DIRAPP}/webapps
  chown manmon_${DIRAPP} ${DATA_DIR}/manmon_${DIRAPP}/webapps
  chown manmon_${DIRAPP} ${DATA_DIR}/manmon_${DIRAPP}/logs
  chmod 700 ${DATA_DIR}/manmon_${DIRAPP}/logs
  mkdir -p ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  chmod 700 ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  chown manmon_${DIRAPP} ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_${DIRAPP}
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  fi
}

create-manmon-db-dirs() {
  DIRAPP="$1"
  echo "Creating directories for ${DIRAPP}-db"
  mkdir -p ${DATA_DIR}/manmon_${DIRAPP}_db/
  chmod 700 ${DATA_DIR}/manmon_${DIRAPP}_db/
  chown manmon_${DIRAPP}_db ${DATA_DIR}/manmon_${DIRAPP}_db/
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_${DIRAPP}_db/
  fi
}

create-tomcat-container() {
  APP="$1"
  IP_END="$2"
  if [ `docker ps -a -q -f "name=manmon-${APP}$"|wc -l` -eq 1 ]
  then
    echo "Container manmon-${APP} exists already - not creating"
  else
    create-manmon-dirs "${APP}"
    echo "Creating application container ${APP}"
    docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=200000 -it -d -m 2560m \
      -v ${DATA_DIR}/manmon_${APP}/webapps:/home/manmon_${APP}/tomcat/webapps --name manmon-${APP} --net manmon \
      -v ${DATA_DIR}/manmon_${APP}/logs:/home/manmon_${APP}/tomcat/logs \
      -v ${DATA_DIR}/java-agent/manmon-${APP}:/var/lib/manmon-java-agent/manmon_${APP} \
      --ip ${IP_PREFIX}.${IP_END} manmon/manmon-${APP}:latest >/dev/null 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating container manmon-${APP}"
      exit 1
    else
      echo "Created container manmon-${APP}"
    fi
    download-war "$APP"
  fi
}

create-hosts-container() {
  APP="hosts"
  IP_END="56"
  if [ `docker ps -a -q -f "name=manmon-${APP}$"|wc -l` -eq 1 ]
  then
    echo "Container manmon-${APP} exists already - not creating"
  else
    create-hosts-dirs-and-copy-keys
    echo "Creating application container ${APP}"
    docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=200000 -it -d -m 2560m \
      -v ${DATA_DIR}/manmon_${APP}/logs:/home/manmon_${APP}/tomcat/logs \
      -v ${DATA_DIR}/manmon_${APP}/.auth/:/home/manmon_${APP}/.auth \
      -v ${DATA_DIR}/manmon_${APP}/webapps:/home/manmon_${APP}/tomcat/webapps \
      -v ${DATA_DIR}/java-agent/manmon-${APP}:/var/lib/manmon-java-agent/manmon_${APP} \
      --net manmon --ip ${IP_PREFIX}.${IP_END} --name manmon-${APP} manmon/manmon-${APP}:latest >/dev/null 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating container manmon-${APP}"
      exit 1
    else
      echo "Created container manmon-${APP}"
    fi
    download-war "$APP"
  fi
}


create-uploader-container() {
  APP="uploader"
  IP_END="52"
  if [ `docker ps -a -q -f "name=manmon-${APP}$"|wc -l` -eq 1 ]
  then
    echo "Container manmon-${APP} exists already - not creating"
  else
    create-uploader-dirs-and-copy-keys
    echo "Creating application container ${APP}"
    docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=200000 -it -d -m 2560m \
      -v ${DATA_DIR}/manmon_${APP}/logs:/home/manmon_${APP}/tomcat/logs \
      -v ${DATA_DIR}/manmon_${APP}/.auth/:/home/manmon_${APP}/.auth \
      -v ${DATA_DIR}/manmon_${APP}/conf:/home/manmon_${APP}/conf \
      -v ${DATA_DIR}/manmon_${APP}/webapps:/home/manmon_${APP}/tomcat/webapps \
      -v ${DATA_DIR}/java-agent/manmon-${APP}:/var/lib/manmon-java-agent/manmon_${APP} \
      --net manmon --ip ${IP_PREFIX}.${IP_END} --name manmon-${APP} manmon/manmon-${APP}:latest >/dev/null 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating container manmon-${APP}"
      exit 1
    else
      echo "Created container manmon-${APP}"
    fi
    download-war "$APP"
  fi
}

create-db-container() {
  DB="$1"
  DBVER="$2"
  DBPWD="$3"
  IP_END="$4"
  if [ `docker ps -a -q -f "name=manmon-${DB}-db$"|wc -l` -eq 1 ]
  then
    echo "Container manmon-${DB}-db exists already - not creating"
  else
    create-manmon-db-dirs "${DB}"
    echo "Creating database container ${DB}"
    docker run --restart unless-stopped --env MMPGUSER=manmon_${DB} --env MMPGPWD="${DBPWD}" --cpu-period=100000 --cpu-quota=25000 \
      -v ${DATA_DIR}/manmon_${DB}_db/:/var/lib/postgresql/${DBVER} --memory-swap -1 -it -d -m 512m --name manmon-${DB}-db --net manmon \
      --ip ${IP_PREFIX}.${IP_END} manmon/manmon-${DB}-db:latest >/dev/null 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating container manmon-${DB}-db"
      exit 1
    else
      echo "Created container manmon-${DB}-db"
    fi
  fi
}

create-certs() {
  if [ ! -d ${DATA_DIR}/manmon_certs ]
  then
    create-certs-dirs
    docker run --rm \
      -v ${DATA_DIR}/manmon_conf:/home/manmon_conf \
      -v ${DATA_DIR}/manmon_certs/.certs:/home/manmon_certs/.certs \
      -v ${DATA_DIR}/manmon_certs/conf:/home/manmon_certs/conf \
      -it manmon/manmon-certs /home/manmon_certs/gen_cert_constants.py $UPLOADHOST 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating constants for certificates and keys"
      exit 1
    else
      docker run --rm -v ${DATA_DIR}/manmon_conf:/home/manmon_conf -v ${DATA_DIR}/manmon_certs/.certs:/home/manmon_certs/.certs -v ${DATA_DIR}/manmon_certs/conf:/home/manmon_certs/conf -it manmon/manmon-certs /home/manmon_certs/gen_keys.sh 2>/dev/null
      if [ "$?" -ne 0 ]
      then
        echo "Error creating certificates and keys"
        exit 1
      fi
    fi
  else
    echo "Certificates and keys directory exists"
  fi
  
  if [ ! -d ${DATA_DIR}/manmon_conf_rpm ]
  then
    create-manmon-conf-rpm-dirs
    docker run -e UPLOADHOST="$UPLOADHOST" -e CONFNAME="$CONF_NAME" -e VER="$PKG_VERSION" -e RELEASE="$PKG_RELEASE" --rm \
      -v ${DATA_DIR}/manmon_certs/.certs:/home/manmon_certs/.certs \
      -v ${DATA_DIR}/manmon_conf_rpm/rpmbuild:/home/mmagent/rpmbuild \
      -v ${DATA_DIR}/manmon_conf:/home/manmon_conf \
      -it manmon/manmon-conf-rpm /home/mmagent/create_pkg.sh 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating configuration RPM"
      exit 1
    fi
  else
    echo "Configuration RPM directory exists"
  fi

  if [ ! -d ${DATA_DIR}/manmon_conf_dpkg ]
  then
    create-manmon-conf-dpkg-dirs
    docker run -e UPLOADHOST="$UPLOADHOST" -e CONFNAME="$CONF_NAME" -e VER="$PKG_VERSION" -e RELEASE="$PKG_RELEASE" --rm -v ${DATA_DIR}/manmon_conf_dpkg/.tmp:/home/mmagent/.tmp -v ${DATA_DIR}/manmon_conf:/home/manmon_conf -it manmon/manmon-conf-dpkg /home/mmagent/create_pkg.sh 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating configuration DPKG"
      exit 1
    fi
  else
    echo "Configuration DPKG directory exists"
  fi
}


create-manmon-conf-rpm-dirs() {
  mkdir -p ${DATA_DIR}/manmon_conf
  chown 100010 ${DATA_DIR}/manmon_conf
  chmod 700 ${DATA_DIR}/manmon_conf
  rm -rf ${DATA_DIR}/manmon_conf_rpm/rpmbuild/SOURCES
  mkdir -p ${DATA_DIR}/manmon_conf_rpm/rpmbuild/SOURCES
  cp ${DATA_DIR}/manmon_certs/.certs/client1.crt  ${DATA_DIR}/manmon_conf_rpm/rpmbuild/SOURCES/.manmon_crt
  cp ${DATA_DIR}/manmon_certs/.certs/client1.key  ${DATA_DIR}/manmon_conf_rpm/rpmbuild/SOURCES/.manmon_key
  cp ${DATA_DIR}/manmon_certs/.certs/ca.crt  ${DATA_DIR}/manmon_conf_rpm/rpmbuild/SOURCES/.manmon_ca
  chown -R 100010 ${DATA_DIR}/manmon_conf_rpm/rpmbuild
  chmod -R 700 ${DATA_DIR}/manmon_conf_rpm/rpmbuild
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_conf/
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_conf_rpm/
  fi
}


create-manmon-conf-dpkg-dirs() {  
  mkdir -p ${DATA_DIR}/manmon_conf
  chown 100010 ${DATA_DIR}/manmon_conf
  chmod 700 ${DATA_DIR}/manmon_conf
  rm -rf ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib/manmon
  mkdir -p ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib/manmon
  cp ${DATA_DIR}/manmon_certs/.certs/client1.crt  ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib/manmon/.manmon_crt
  cp ${DATA_DIR}/manmon_certs/.certs/client1.key  ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib/manmon/.manmon_key
  cp ${DATA_DIR}/manmon_certs/.certs/ca.crt  ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib/manmon/.manmon_ca
  chown -R 100010 ${DATA_DIR}/manmon_conf_dpkg/.tmp
  chmod 700 ${DATA_DIR}/manmon_conf_dpkg/
  chmod 700 ${DATA_DIR}/manmon_conf_dpkg/.tmp
  chmod 700 ${DATA_DIR}/manmon_conf_dpkg/.tmp/var
  chmod 700 ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib
  chmod 700 ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib/manmon
  chmod 400 ${DATA_DIR}/manmon_conf_dpkg/.tmp/var/lib/manmon/.manmon_*
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_conf_dpkg/
  fi
}

create-certs-dirs() {
  mkdir -p ${DATA_DIR}/manmon_certs/conf
  mkdir -p ${DATA_DIR}/manmon_certs/.certs
  chown 100008 ${DATA_DIR}/manmon_certs/conf
  chown 100008 ${DATA_DIR}/manmon_certs/.certs
  chmod 700 ${DATA_DIR}/manmon_certs/conf
  chmod 700 ${DATA_DIR}/manmon_certs/.certs
  chown 100008 ${DATA_DIR}/manmon_certs
  chmod 700 ${DATA_DIR}/manmon_certs
  mkdir -p ${DATA_DIR}/manmon_conf
  chown 100008 ${DATA_DIR}/manmon_conf
  chmod 700 ${DATA_DIR}/manmon_conf
  chown 100008 ${DATA_DIR}/manmon_certs
  chmod 700 ${DATA_DIR}/manmon_certs
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_certs
  fi
}


create-zookeeper-dirs() {
  mkdir -p ${DATA_DIR}/manmon_zookeeper/data/
  mkdir -p ${DATA_DIR}/manmon_zookeeper/logs/
  chown 100002 ${DATA_DIR}/manmon_zookeeper
  chown 100002 ${DATA_DIR}/manmon_zookeeper/data
  chown 100002 ${DATA_DIR}/manmon_zookeeper/logs
  chmod 700 ${DATA_DIR}/manmon_zookeeper
  chmod 700 ${DATA_DIR}/manmon_zookeeper/data
  chmod 700 ${DATA_DIR}/manmon_zookeeper/logs
  mkdir -p ${DATA_DIR}/java-agent/manmon-zookeeper
  chown 100002 ${DATA_DIR}/java-agent/manmon-zookeeper
  chmod 700 ${DATA_DIR}/java-agent/manmon-zookeeper
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_zookeeper/
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/java-agent/manmon-zookeeper/
  fi
}

create-zookeeper() {
  if [ `docker ps -a -q -f "name=manmon-zookeeper$"|wc -l` -eq 1 ]
  then
    echo "Container manmon-zookeeper exists already - not creating"
  else
    create-zookeeper-dirs
    docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=10000 --net manmon --ip ${IP_PREFIX}.21 -it -d -m 128m \
      -v ${DATA_DIR}/java-agent/manmon-zookeeper:/var/lib/manmon-java-agent/manmon_zookeeper \
      -v ${DATA_DIR}/manmon_zookeeper/data:/home/manmon_zk/data -v ${DATA_DIR}/manmon_zookeeper/logs:/home/manmon_zk/zookeeper/logs --name manmon-zookeeper manmon/manmon-zookeeper >/dev/null  2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating container manmon-zookeeper"
      exit 1
    else
      echo "Created container manmon-zookeeper"
    fi
  fi
}


create-kafka-dirs() {
  mkdir -p ${DATA_DIR}/manmon_kafka/data/
  chown 100003 ${DATA_DIR}/manmon_kafka
  mkdir -p ${DATA_DIR}/manmon_kafka/logs
  chown 100003 ${DATA_DIR}/manmon_kafka/data
  chown 100003 ${DATA_DIR}/manmon_kafka/logs
  chmod 700 ${DATA_DIR}/manmon_kafka
  chmod 700 ${DATA_DIR}/manmon_kafka/data
  chmod 700 ${DATA_DIR}/manmon_kafka/logs
  mkdir -p  ${DATA_DIR}/java-agent/manmon-kafka
  chown manmon_kafka ${DATA_DIR}/java-agent/manmon-kafka
  chmod 700 ${DATA_DIR}/java-agent/manmon-kafka
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_kafka/
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/java-agent/manmon-kafka
  fi
}
create-hosts-dirs-and-copy-keys() {
  create-manmon-dirs "hosts"
  mkdir -p ${DATA_DIR}/manmon_hosts/.auth
  chmod 700 ${DATA_DIR}/manmon_hosts/.auth
  chown manmon_hosts ${DATA_DIR}/manmon_hosts/.auth

  if [ ! -f ${DATA_DIR}/manmon_hosts/.auth/.tomcat_constants ]
  then
    cp -p ${DATA_DIR}/manmon_conf/.tomcat_constants ${DATA_DIR}/manmon_hosts/.auth/.tomcat_constants
    chown manmon_hosts ${DATA_DIR}/manmon_hosts/.auth/.tomcat_constants
    chmod 400 ${DATA_DIR}/manmon_hosts/.auth/.tomcat_constants
  fi
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_hosts/
  fi
}

create-uploader-dirs-and-copy-keys() {
  mkdir -p ${DATA_DIR}/manmon_uploader/.auth
  mkdir -p ${DATA_DIR}/manmon_uploader/conf
  mkdir -p ${DATA_DIR}/manmon_uploader/webapps
  mkdir -p ${DATA_DIR}/manmon_uploader/logs
  chmod 700 ${DATA_DIR}/manmon_uploader/.auth
  chmod 700 ${DATA_DIR}/manmon_uploader
  chmod 700 ${DATA_DIR}/manmon_uploader/conf
  chmod 700 ${DATA_DIR}/manmon_uploader/webapps
  chmod 700 ${DATA_DIR}/manmon_uploader/logs
  chown 100006 ${DATA_DIR}/manmon_uploader/.auth
  chown 100006 ${DATA_DIR}/manmon_uploader/conf
  chown 100006 ${DATA_DIR}/manmon_uploader
  chown 100006 ${DATA_DIR}/manmon_uploader/webapps
  chown 100006 ${DATA_DIR}/manmon_uploader/logs
  mkdir -p ${DATA_DIR}/java-agent/manmon-uploader
  chmod 700 ${DATA_DIR}/java-agent/manmon-uploader
  chown 100006 ${DATA_DIR}/java-agent/manmon-uploader

  if [ ! -f ${DATA_DIR}/manmon_uploader/.auth/.cacerts.jks ]
  then
    cp -p ${DATA_DIR}/manmon_conf/.tomcat_constants ${DATA_DIR}/manmon_uploader/.auth/.tomcat_constants
    cp -p ${DATA_DIR}/manmon_certs/.certs/mycert.p12 ${DATA_DIR}/manmon_uploader/.auth/.mycert.p12
    cp -p ${DATA_DIR}/manmon_certs/.certs/cacerts.jks ${DATA_DIR}/manmon_uploader/.auth/.cacerts.jks
    chown 100006 ${DATA_DIR}/manmon_uploader/.auth/.mycert.p12
    chown 100006 ${DATA_DIR}/manmon_uploader/.auth/.cacerts.jks
    chmod 400 ${DATA_DIR}/manmon_uploader/.auth/.mycert.p12
    chmod 400 ${DATA_DIR}/manmon_uploader/.auth/.cacerts.jks
    chown 100006 ${DATA_DIR}/manmon_uploader/.auth/.tomcat_constants
    chmod 400 ${DATA_DIR}/manmon_uploader/.auth/.tomcat_constants
    
    cp -p ${DATA_DIR}/manmon_certs/.certs/uploader-server.xml ${DATA_DIR}/manmon_uploader/conf/server.xml
    chown 100006 ${DATA_DIR}/manmon_uploader/conf/server.xml
    chmod 400 ${DATA_DIR}/manmon_uploader/conf/server.xml
  fi
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_uploader/
  fi
}

create-kafka() {
if [ `docker ps -a -q -f "name=manmon-kafka$"|wc -l` -eq 1 ]
  then
    echo "Container manmon-kafka exists already - not creating"
  else
    create-kafka-dirs
    docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=100000 --net manmon --ip ${IP_PREFIX}.22 -it -d -m 2048m -v ${DATA_DIR}/manmon_kafka/data:/home/manmon_kafka/data -v ${DATA_DIR}/manmon_kafka/logs:/home/manmon_kafka/kafka/logs \
      -v ${DATA_DIR}/java-agent/manmon-kafka:/var/lib/manmon-java-agent/manmon_kafka \
      --name manmon-kafka manmon/manmon-kafka >/dev/null  2>/dev/null 
    if [ "$?" -ne 0 ]
    then
      echo "Error creating container manmon-kafka"
      exit 1
    else
      echo "Created container manmon-kafka"
    fi
  fi
}
create-data-loader() {
  DIRAPP="data_loader"

  if [ `docker ps -a -q -f "name=manmon-data-loader$"|wc -l` -eq 1 ]
  then
    echo "Container manmon-data-loader exists already - not creating"
  else
    create-data-loader-dirs
    download-manmon-data-loader 
    docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=50000 --net manmon --ip ${IP_PREFIX}.26 -it -d -m 1150m \
      -v ${DATA_DIR}/manmon_data_loader/logs:/home/manmon_data_loader/logs \
      -v ${DATA_DIR}/java-agent/manmon-data-loader:/var/lib/manmon-java-agent/manmon_data_loader \
      -v ${DATA_DIR}/manmon_data_loader/jar:/home/manmon_data_loader/jar \
      --name manmon-data-loader manmon/manmon-data-loader >/dev/null  2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating container manmon-data-loader"
      exit 1
    else
      echo "Created container manmon-data-loader"
    fi
  fi
}

create-data-loader-dirs() {
  echo "Creating directories for ${DIRAPP}"
  mkdir -p ${DATA_DIR}/manmon_${DIRAPP}/
  chmod 700 ${DATA_DIR}/manmon_${DIRAPP}/
  chown manmon_${DIRAPP} ${DATA_DIR}/manmon_${DIRAPP}/ 
  mkdir -p ${DATA_DIR}/manmon_${DIRAPP}/jar
  chmod 700 ${DATA_DIR}/manmon_${DIRAPP}/jar
  chown manmon_${DIRAPP} ${DATA_DIR}/manmon_${DIRAPP}/jar
  mkdir -p ${DATA_DIR}/manmon_${DIRAPP}/logs
  chmod 700 ${DATA_DIR}/manmon_${DIRAPP}/logs
  chown manmon_${DIRAPP} ${DATA_DIR}/manmon_${DIRAPP}/logs
  mkdir -p ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  chown manmon_${DIRAPP} ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  chmod 700 ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  if $SELINUXENABLED
  then
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/manmon_${DIRAPP}
    chcon -Rt svirt_sandbox_file_t ${DATA_DIR}/java-agent/manmon-${DIRAPP}
  fi
}

download-manmon-data-loader() {
  echo "Downloading data loader JAR"
  wget -q -O ${DATA_DIR}/manmon_data_loader/jar/manmon-dbloader.jar https://manmon.net/war/manmon-dbloader.jar
}

create-users() {
  for line in `cat users`
  do
    userid=`echo "$line" | awk '{split($0,a,"#"); print a[1]}'`
    username=`echo "$line" | awk '{split($0,a,"#"); print a[2]}'`
 
    if ! id -u "$username" > /dev/null 2>&1; then
      useradd -M -N -u "$userid" "$username"
      echo "Added user $username"
    fi
  done
}
