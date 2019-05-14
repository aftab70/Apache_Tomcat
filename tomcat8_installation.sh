#!/bin/bash



echo "System is updating and upgrading, please wait for a while"

apt-get update -y
#apt-get upgrade -y
sudo apt-get install default-jdk -y



echo "Creating a directory to download required packages"

mkdir /opt/
wget --directory-prefix=/opt/ http://mirrors.estointernet.in/apache/tomcat/tomcat-8/v8.5.38/bin/apache-tomcat-8.5.38.tar.gz

sudo groupadd $SYSGROUP
sudo useradd -s /bin/false -g $SYSUSER -d /opt/tomcat $SYSUSER

sudo mkdir /opt/$TOMCATHOME
sudo tar xzvf /opt/apache-tomcat-8.5.38.tar.gz -C /opt/$TOMCATHOME --strip-components=1

sudo chgrp -R $SYSUSER /opt/$TOMCATHOME
sudo chmod -R g+r /opt/$TOMCATHOME/conf
sudo chmod g+x /opt/$TOMCATHOME/conf

sudo chown -R $SYSUSER /opt/$TOMCATHOME/webapps/ 
sudo chown -R $SYSUSER /opt/$TOMCATHOME/work/
sudo chown -R $SYSUSER /opt/$TOMCATHOME/temp/
sudo chown -R $SYSUSER /opt/$TOMCATHOME/logs/

#####################################################################################################################
#AuthBind configuration in Tomcat port 80, 443

sudo apt install authbind
sudo touch /etc/authbind/byport/{443,80}
sudo chmod 500 /etc/authbind/byport/{443,80}
sudo chown tcat:tcat /etc/authbind/byport/{443,80}
sudo sed -i 's/8080/80/g' /opt/tomcat/conf/server.xml
sudo sed -i 's/8443/443/g' /opt/tomcat/conf/server.xml
sudo echo "exec authbind --deep "$PRGDIR"/"$EXECUTABLE" start "$@"" >> /opt/tomcat/bin/startup.sh
sudo systemctl restart tcat.service












