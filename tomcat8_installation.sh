   Apache Tomcat setup 8.5.41 with Ubuntu 16.04
-------------------------------------------------

timedatectl set-timezone Asia/Kolkata
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install default-jdk -y
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
cd /tmp
sudo apt-get install curl -y
curl -O http://mirrors.estointernet.in/apache/tomcat/tomcat-8/v8.5.41/bin/apache-tomcat-8.5.41.tar.gz
sudo mkdir /opt/tomcat
sudo tar xzvf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1
cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/
sudo update-java-alternatives -l
sudo nano /etc/systemd/system/tomcat.service

sudo nano /etc/systemd/system/tomcat.service


[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target


sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl status tomcat
sudo ufw allow 8080
sudo ufw allow 8443
sudo systemctl enable tomcat


#Configure Tomcat Web Management Interface


sudo nano /opt/tomcat/conf/tomcat-users.xml

<tomcat-users . . .>
    <user username="admin" password="password" roles="manager-gui,admin-gui"/>
</tomcat-users>



sudo nano /opt/tomcat/webapps/manager/META-INF/context.xml

<Context antiResourceLocking="false" privileged="true" >
  <!--<Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />-->
</Context>

sudo nano /opt/tomcat/webapps/host-manager/META-INF/context.xml

<Context antiResourceLocking="false" privileged="true" >
  <!--<Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />-->
</Context>

sudo systemctl restart tomcat


           Access the Web Interface
----------------------------------------

      http://server_domain_or_IP:8080


   AuthBind configuration in Tomcat port 80, 443
-----------------------------------------------------

sudo apt install authbind -y
sudo touch /etc/authbind/byport/{443,80}
sudo chmod 500 /etc/authbind/byport/{443,80}
sudo chown tomcat:tomcat /etc/authbind/byport/{443,80}
sudo sed -i 's/8080/80/g' /opt/tomcat/conf/server.xml
sudo sed -i 's/8443/443/g' /opt/tomcat/conf/server.xml
Sudo nano /opt/tomcat/bin/startup.sh

#Comment the last line and add the given line in startup.sh file

exec authbind --deep "$PRGDIR"/"$EXECUTABLE" start "$@"

#Save and Exit

sudo systemctl restart tomcat.service

--------------------------------------------------------------------------


                Self Sign SSL configuration using Tomcat 8
--------------------------------------------------------------------------

keytool -genkey -alias Your_own_domain -keyalg RSA -keystore /etc/pki/keystore

Need to edit server.xml file to add given param to configure ssl

<Connector port="8443" protocol="HTTP/1.1"
                connectionTimeout="20000"
                redirectPort="8443"
                SSLEnabled="true"
                scheme="https"
                secure="true"
                sslProtocol="TLS"
                keystoreFile="/etc/pki/keystore"
                keystorePass="_password_" />


sudo systemctl restart tomcat.service

--------------------------------------------------------------------------
         
         Threads configuration in port 80 and Port 443
-------------------------------------------------------------------------------------

For port 443

      <Connector port="8443" protocol="HTTP/1.1"
                 connectionTimeout="20000"
                 minSpareThreads="10"
                 maxSpareThreads="100"
                 maxthreads="400"
                 acceptCount="100"
                 maxKeepAliveRequests=""
                 redirectPort="8443"
                 SSLEnabled="true"
                 scheme="https"
                 secure="true"
                 sslProtocol="TLS"
                 keystoreFile="/etc/pki/keystore"
                 keystorePass="_password_" />

For port 80 
	
	<Connector port="80" protocol="HTTP/1.1"
                 connectionTimeout="20000"
                 minSpareThreads="10"
                 maxSpareThreads="100"
                 maxthreads="400"
                 acceptCount="100"
                 maxKeepAliveRequests=""	
                 redirectPort="443" />


------------------------------------------------------------------------


               VirtualHost configuration in Apache Tomcat 
-------------------------------------------------------------------------------------

Your domain must be ping with your tomcat server IP address for virtual host.

File to be edit conf/server.xml
-------------------------------------------------------------------------------------

<Host name="www.example.com"  appBase="webapps/example/" unpackWARs="true" autoDeploy="true">
<Alias>www.example.com</Alias>

<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
       	prefix="local_access_log" suffix=".txt"
       	pattern="%h %l %u %t &quot;%r&quot; %D %s %b" />

<Context path="" docBase="/opt/tomcat/webapps/example/"
   debug="0" reloadable="true"/>
</Host>


- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


<Host name="www.example.com"  appBase="webapps/example/" unpackWARs="true" autoDeploy="true">
<Alias>www.example.com</Alias>

<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
       	prefix="local_access_log" suffix=".txt"
       	pattern="%h %l %u %t &quot;%r&quot; %D %s %b" />

<Context path="" docBase="/opt/tomcat/webapps/example/"
   debug="0" reloadable="true"/>
</Host>


        Port Number based virtual hosting in Apache Tomcat 

<Service name="service_name">
    <Connector port="PORT_NUMBER" protocol="HTTP/1.1" connectionTimeout="20000" minSpareThreads="10" maxThreads="100" compression="on" compressableMimeType="text/html,text/xml,text/plain" redirectPort="8467" />
      <!--- New Line Added for HTTPS Connection -->
    <Connector SSLEnabled="true" acceptCount="100" clientAuth="false"
    disableUploadTimeout="true" enableLookups="false" maxThreads="100"
    port="8467" keystoreFile="/home/ginger/.keystore" keystorePass="123456"
    protocol="org.apache.coyote.http11.Http11NioProtocol" scheme="https"
    secure="true" sslProtocol="TLS" />
    <Connector port="8009" protocol="AJP/1.3" redirectPort="8462" />
    <Engine name="Catalina" defaultHost="localhost">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>
      <Host name="localhost"  appBase="webapps/advertisement"
            unpackWARs="true" autoDeploy="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %D %s %b %{User-Agent}i %{Referer}i" />
      </Host>
    </Engine>
</Service>



-------------------------------------------------------------------------------------

          Configuration of JVM memory for Apache Tomcat 
-------------------------------------------------------------------------------------

To configure tomcat need to edit and replace the memory for JVM in Tomcat

sudo nano /etc/systemd/system/tomcat.service

Environment='CATALINA_OPTS=-Xms712M -Xmx1224M -server -XX:+UseParallelGC'

Save and exit

systemctl daemon-reload

systemctl restart tomcat.service

systemctl status tomcat.service

------------------------------------------------------------------------

            Configuration of open file limit in Apache Tomcat 
------------------------------------------------------------------------------------
