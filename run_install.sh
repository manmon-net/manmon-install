source variables
. functions.sh
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

if [ ! -d /home/manmon-data ]
then
  mkdir -p /home/manmon-data
  if [ -f /usr/sbin/selinuxenabled ]
  then
    if /usr/sbin/selinuxenabled
    then
      chcon -Rt svirt_sandbox_file_t /home/manmon-data/
    fi
  fi
  add-users
  create-initial-dirs
fi

if [ `docker ps -a -q -f "name=manmon-auth-db$"|wc -l` -eq 1 ]
then
  echo "Container manmon-auth-db exists already - not creating"
else
  create-manmon-auth-db-dirs
  docker run --restart unless-stopped --env MMPGUSER=manmon_auth --env MMPGPWD=adfjklBAjkn3124Bbjkav248gAnj --cpu-period=100000 --cpu-quota=25000 \
    -v /home/manmon-data/manmon-auth-db/:/var/lib/postgresql/10 --memory-swap -1 -it -d -m 512m --name manmon-auth-db --net manmon \
    --ip ${IP_PREFIX}.41 manmon/manmon-auth-db:latest 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating container manmon-auth-db"
    exit 1
  else
    echo "Created contained manmon-auth-db"
  fi
fi

if [ `docker ps -a -q -f "name=manmon-uploader-db$"|wc -l` -eq 1 ]
then
  echo "Container manmon-uploader-db exists already - not creating"
else
  create-manmon-upload-db-dirs
  docker run --restart unless-stopped --env MMPGUSER=manmon_uploader --env MMPGPWD=mnjABSnmo1235Njakn054amkabjnj6Maouibn --cpu-period=100000 --cpu-quota=25000 \
    -v /home/manmon-data/manmon-uploader-db/:/var/lib/postgresql/10 \
    --memory-swap -1 -it -d -m 512m --name manmon-uploader-db --net manmon --ip ${IP_PREFIX}.42 manmon/manmon-uploader-db:latest 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating container manmon-uploader-db"
    exit 1
  else
    echo "Created container manmon-uploader-db"
  fi
fi
if [ `docker ps -a -q -f "name=manmon-auth$"|wc -l` -eq 1 ]
then
  echo "Container manmon-auth exists already - not creating"
else
  create-manmon-auth-dirs
  docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=200000 -it -d -m 2560m \
    -v /home/manmon-data/manmon-auth/webapps:/home/manmon-auth/tomcat/webapps --name manmon-auth --net manmon \
    --ip ${IP_PREFIX}.51 manmon/manmon-auth:latest
  if [ "$?" -ne 0 ]
  then
    echo "Error creating container manmon-auth"
    exit 1
  else
    echo "Created container manmon-auth"
  fi
fi

if [ ! -d /home/manmon-data/manmon-certs ]
then
  create-certs-dirs
  docker run --rm \
    -v /home/manmon-data/manmon-conf:/home/manmon-conf \
    -v /home/manmon-data/manmon-certs/.certs:/home/manmon-certs/.certs \
    -v /home/manmon-data/manmon-certs/conf:/home/manmon-certs/conf \
    -it manmon/manmon-certs /home/manmon-certs/gen_cert_constants.py $UPLOADHOST 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating constants for certificates and keys"
    exit 1
  else
    docker run --rm -v /home/manmon-data/manmon-conf:/home/manmon-conf -v /home/manmon-data/manmon-certs/.certs:/home/manmon-certs/.certs -v /home/manmon-data/manmon-certs/conf:/home/manmon-certs/conf -it manmon/manmon-certs /home/manmon-certs/gen_keys.sh 2>/dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Error creating certificates and keys"
      exit 1
    fi
  fi
else
  echo "Certificates and keys directory exists"
fi

if [ ! -d /home/manmon-data/manmon-conf-rpm ]
then
  create-manmon-conf-rpm-dirs
  docker run -e UPLOADHOST="$UPLOADHOST" -e CONFNAME="$CONF_NAME" -e VER="$PKG_VERSION" -e RELEASE="$PKG_RELEASE" --rm \
    -v /home/manmon-data/manmon-certs/.certs:/home/manmon-certs/.certs \
    -v /home/manmon-data/manmon-conf-rpm/rpmbuild:/home/mmagent/rpmbuild \
    -v /home/manmon-data/manmon-conf:/home/manmon-conf \
    -it manmon/manmon-conf-rpm /home/mmagent/create_pkg.sh 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating configuration RPM"
    exit 1
  fi
else
  echo "Configuration RPM directory exists"
fi

if [ ! -d /home/manmon-data/manmon-conf-dpkg ]
then
  create-manmon-conf-dpkg-dirs
  docker run -e UPLOADHOST="$UPLOADHOST" -e CONFNAME="$CONF_NAME" -e VER="$PKG_VERSION" -e RELEASE="$PKG_RELEASE" --rm -v /home/manmon-data/manmon-conf-dpkg/.tmp:/home/mmagent/.tmp -v /home/manmon-data/manmon-conf:/home/manmon-conf -it manmon/manmon-conf-dpkg /home/mmagent/create_pkg.sh 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating configuration DPKG"
    exit 1
  fi
else
  echo "Configuration DPKG directory exists"
fi

if [ `docker ps -a -q -f "name=manmon-zookeeper$"|wc -l` -eq 1 ]
then
  echo "Container manmon-zookeeper exists already - not creating"
else
  create-zookeeper-dirs
  docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=10000 --net manmon --ip ${IP_PREFIX}.21 -it -d -m 128m -v /home/manmon-data/manmon-zookeeper/data:/home/manmon_zk/data -v /home/manmon-data/manmon-zookeeper/logs:/home/manmon_zk/zookeeper/logs --name manmon-zookeeper manmon/manmon-zookeeper >/dev/null  2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating container manmon-zookeeper"
    exit 1
  else
    echo "Created container manmon-zookeeper"
  fi
fi

if [ `docker ps -a -q -f "name=manmon-kafka$"|wc -l` -eq 1 ]
then
  echo "Container manmon-kafka exists already - not creating"
else
  create-kafka-dirs
  docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=100000 --net manmon --ip ${IP_PREFIX}.22 -it -d -m 2048m -v /home/manmon-data/manmon-kafka/data:/home/manmon_kafka/data -v /home/manmon-data/manmon-kafka/logs:/home/manmon_kafka/kafka/logs --name manmon-kafka manmon/manmon-kafka >/dev/null  2>/dev/null 
  if [ "$?" -ne 0 ]
  then
    echo "Error creating container manmon-kafka"
    exit 1
  else
    echo "Created container manmon-kafka"
  fi
fi

if [ `docker ps -a -q -f "name=manmon-uploader$"|wc -l` -eq 1 ]
then
  echo "Container manmon-uploader exists already - not creating"
else
  create-uploader-dirs-and-copy-keys
  docker run --restart unless-stopped --cpu-period=100000 --cpu-quota=200000 -it -d -m 2560m \
    -v /home/manmon-data/manmon-uploader/logs:/home/manmon-uploader/tomcat/logs \
    -v /home/manmon-data/manmon-uploader/.auth/:/home/manmon-uploader/.auth \
    -v /home/manmon-data/manmon-uploader/conf:/home/manmon-uploader/conf \
    -v /home/manmon-data/manmon-uploader/webapps:/home/manmon-uploader/tomcat/webapps \
    --name manmon-uploader --net manmon --ip ${IP_PREFIX}.52 manmon/manmon-uploader >/dev/null 2>/dev/null
  if [ "$?" -ne 0 ]
  then
    echo "Error creating container manmon-uploader"
    exit 1
  else
    echo "Created container manmon-uploader"
  fi
fi






