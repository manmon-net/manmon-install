#!/bin/bash
. functions.sh

echo "Creating users"
create-users

echo "Creating certificates and keys"
create-certs

echo "Creating Zookeeper container"
create-zookeeper

echo "Creating Kafka container"
create-kafka

echo "Creating database containers"
for line in `cat databases`
do
  IP_END=`echo "$line" | awk '{split($0,a,"#"); print a[1]}'`
  DB_AND_USERNAME=`echo "$line" | awk '{split($0,a,"#"); print a[2]}'`
  DBPWD=`echo "$line" | awk '{split($0,a,"#"); print a[3]}'`
  DBVER=`echo "$line" | awk '{split($0,a,"#"); print a[4]}'`
  create-db-container $DB_AND_USERNAME $DBVER $DBPWD $IP_END  
done

echo "Creating Tomcat containers"
for line in `cat tomcat_containers`
do
  APP=`echo "$line" | awk '{split($0,a,"#"); print a[1]}'`
  IP_END=`echo "$line" | awk '{split($0,a,"#"); print a[2]}'`
  create-tomcat-container $APP $IP_END
done

echo "Creating uploader container"
create-uploader-container

echo "Creating manmon-data-loader container"
create-data-loader

echo "Creating manmon-hosts container"
create-hosts-container
