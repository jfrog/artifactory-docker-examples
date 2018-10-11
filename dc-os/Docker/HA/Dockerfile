FROM docker.bintray.io/jfrog/artifactory-pro:6.5.0

MAINTAINER jainishs@jfrog.com

# We download all the usual JDBC drivers available so we can configure them at runtime
RUN curl -L -o  /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar
RUN apt-get update && apt-get install -y dnsutils

COPY run.sh /runArtifactory.sh

# Dynamic configurations
COPY files/plugins/inactiveServerCleaner.groovy /tmp/inactiveServerCleaner.groovy
COPY server.xml /opt/jfrog/artifactory/tomcat/conf/server.xml
COPY binarystore.xml /tmp/binarystore.xml
COPY artifactory.config.xml /tmp/artifactory.config.xml

# Pre-Populated keys
RUN mkdir -p /var/opt/jfrog/artifactory/access/etc/keys/
RUN mkdir -p /var/opt/jfrog/artifactory/etc/security/
ADD files/access/etc/keys/private.key /var/opt/jfrog/artifactory/access/etc/keys/private.key
ADD files/access/etc/keys/root.crt /var/opt/jfrog/artifactory/access/etc/keys/root.crt
ADD files/security/communication.key /var/opt/jfrog/artifactory/communication.key

ENTRYPOINT /runArtifactory.sh
