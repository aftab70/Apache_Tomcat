   Apache Tomcat setup 8.5.41 with Ubuntu 16.04
----------------------------------------------------

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
---------------------------------------------------
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
-----------------------------------------------------

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

<Connector port="443" protocol="HTTP/1.1"
                connectionTimeout="20000"
                redirectPort="443"
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

      <Connector port="443" protocol="HTTP/1.1"
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


               VirtualHost configuration in Apache Tomcat 
-------------------------------------------------------------------------------------

#Your domain must be ping with your tomcat server IP address for virtual host.
#File to be edit conf/server.xml
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


#        Port Number based virtual hosting in Apache Tomcat

<Service name="app1">
   <Connector port="8081" protocol="org.apache.coyote.http11.Http11NioProtocol" 
           connectionTimeout="20000" 
           redirectPort="8443" />
   <Engine name="Catalina" defaultHost="localhost">
      <Host name="localhost"  appBase="app1"
        unpackWARs="true" autoDeploy="true">
      </Host>
   </Engine>
</Service>

<Service name="app2">
   <Connector port="8082" protocol="org.apache.coyote.http11.Http11NioProtocol" 
           connectionTimeout="20000" 
           redirectPort="8443" />
   <Engine name="Catalina" defaultHost="localhost">
      <Host name="localhost"  appBase="app2"
        unpackWARs="true" autoDeploy="true">
      </Host>
   </Engine>
</Service>


-------------------------------------------------------------------------------------

          Configuration of JVM memory for Apache Tomcat 
-------------------------------------------------------------------------------------

# To configure tomcat need to edit and replace the memory for JVM in Tomcat

sudo nano /etc/systemd/system/tomcat.service

Environment='CATALINA_OPTS=-Xms712M -Xmx1224M -server -XX:+UseParallelGC'

Save and exit

systemctl daemon-reload

systemctl restart tomcat.service

systemctl status tomcat.service

------------------------------------------------------------------------

       Configuration of open file limit in Apache Tomcat 
------------------------------------------------------------------------

#Step 1:- First sysAdmin need to check maximum capability of system.
 
user@ubuntu:~$ cat /proc/sys/fs/file-max


708444


#Step 2:- Now need to verify available limit by using following commands.

user@ubuntu:~$ ulimit -n


1024

#Step 3 :- To increase the available limit to say 200000 use the following commands.

user@ubuntu:~$ sudo vim /etc/sysctl.conf

# add the following line to it


fs.file-max = 200000

#Step 4 :- Need to  run this to refresh with new config

user@ubuntu:~$ sudo sysctl -p

#Step 5 :--Now need to edit the following file


user@ubuntu:~$ sudo vim /etc/security/limits.conf

# add following lines to it

* soft  nofile  200000   
* hard  nofile  200000
your_username  soft  nofile  200000
your_username  nofile  200000
root soft nofile 200000   
root hard nofile 200000


Save and exit

#Step 6 :-- Now need to edit the following file sudo vim /etc/pam.d/common-session


user@ubuntu:~$ sudo vim /etc/pam.d/common-session

# add this line to it


session required pam_limits.so



#Step 7 :- Now need to  logout and login and try the following command to get effects.

user@ubuntu:~$ ulimit -n
200000



After configure ulimit in system, We need to configure tomcat for open files limit by following the steps,


#Step1 :- Need to check PID of tomcat by following the commands 


 systemctl status tomcat.service

Now you should see like this output grep the tomcat service main process ID

Loaded: loaded (/etc/systemd/system/tomcat.service; disabled; vendor preset: enabled)
   Active: active (running) since Mon 2019-02-25 14:59:53 IST; 31min ago
  Process: 26977 ExecStop=/opt/tomcat/bin/shutdown.sh (code=exited, status=0/SUCCESS)
  Process: 27041 ExecStart=/opt/tomcat/bin/startup.sh (code=exited, status=0/SUCCESS)
 Main PID: 27049 (java)
   CGroup: /system.slice/tomcat.service
           └─27049 /usr/lib/jvm/java-1.8.0-openjdk-amd64/jre/bin/java -Djava.util.logging.config.file=/opt/tomca

Feb 25 14:59:53 ginger-Lenovo-H50-50 systemd[1]: Starting Apache Tomcat Web Application Container...
Feb 25 14:59:53 ginger-Lenovo-H50-50 systemd[1]: Started Apache Tomcat Web Application Container.


#Step 2:-- Now you need to see open files limits by tomcat process id like this :--

cat /proc/<processId>/limits

Limit                     Soft Limit           Hard Limit           Units     
Max cpu time              unlimited            unlimited            seconds   
Max file size             unlimited            unlimited            bytes     
Max data size             unlimited            unlimited            bytes     
Max stack size            8388608              unlimited            bytes     
Max core file size        0                    unlimited            bytes     
Max resident set          unlimited            unlimited            bytes     
Max processes             47597                47597                processes 
Max open files            8192                 8192                 files     
Max locked memory         65536                65536                bytes     
Max address space         unlimited            unlimited            bytes     
Max file locks            unlimited            unlimited            locks     
Max pending signals       47597                47597                signals   
Max msgqueue size         819200               819200               bytes     
Max nice priority         0                    0                    
Max realtime priority     0                    0                    
Max realtime timeout      unlimited            unlimited            us        



#Step 3:-- Now if you want to change open files limit of tomcat web server you need to edit the tomcat’s service file located in vim /etc/systemd/system/tomcat.service

vim /etc/systemd/system/tomcat.service

Open and add lines after [Services] like this 

[Service]
LimitNOFILE=8192

The completed example is given below:--
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
LimitNOFILE=10192
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

Save and Exit

#To get effects on tomcat services you need to restart the tomcat service but before that you must have to reload the daemons by using the given commands:--

systemctl daemon-reload
systemctl restart tomcat.service
systemctl status tomcat.service

#To  get again status of tomcat open files limit use the given commands with new tomcat PID 
cat /proc/8005/limits
#Now you should get output like that :--

Limit                     Soft Limit           Hard Limit           Units     
Max cpu time              unlimited            unlimited            seconds   
Max file size             unlimited            unlimited            bytes     
Max data size             unlimited            unlimited            bytes     
Max stack size            8388608              unlimited            bytes     
Max core file size        0                    unlimited            bytes     
Max resident set          unlimited            unlimited            bytes     
Max processes             47597                47597                processes 
Max open files            100000               100000               files     
Max locked memory         65536                65536                bytes     
Max address space         unlimited            unlimited            bytes     
Max file locks            unlimited            unlimited            locks     
Max pending signals       47597                47597                signals   
Max msgqueue size         819200               819200               bytes     
Max nice priority         0                    0                    
Max realtime priority     0                    0                    
Max realtime timeout      unlimited            unlimited            us        

#Now our user limit for tomcat’s open files configuration is completed. 
#Reference url mentioned below:--
#https://gist.github.com/luckydev/b2a6ebe793aeacf50ff15331fb3b519d
#https://stackoverflow.com/questions/41272726/really-solve-too-many-open-files-at-a-process-level-not-on-global-ubuntu-level

