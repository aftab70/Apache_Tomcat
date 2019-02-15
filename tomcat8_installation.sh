#!/bin/bash



echo "System is updating and upgrading, please wait for a while"

apt-get update -y
apt-get upgrade -y
sudo apt-get install default-jdk -y



echo "Creating a directory to download required packages"

mkdir /opt/
wget --directory-prefix=/opt/ http://mirrors.estointernet.in/apache/tomcat/tomcat-8/v8.5.38/bin/apache-tomcat-8.5.38.tar.gz

sudo groupadd $SYSGROUP
sudo useradd -s /bin/false -g $SYSUSER -d /opt/tomcat $SYSUSER

sudo mkdir /opt/$TOMCATHOME
sudo tar xzvf /opt/tapache-tomcat-8.5.38.tar.gz -C /opt/$TOMCATHOME --strip-components=1

sudo chgrp -R $SYSUSER /opt/$TOMCATHOME
sudo chmod -R g+r /opt/$TOMCATHOME/conf
sudo chmod g+x /opt/$TOMCATHOME/conf

sudo chown -R $SYSUSER /opt/$TOMCATHOME/webapps/ 
sudo chown -R $SYSUSER /opt/$TOMCATHOME/work/
sudo chown -R $SYSUSER /opt/$TOMCATHOME/temp/
sudo chown -R $SYSUSER /opt/$TOMCATHOME/logs/











