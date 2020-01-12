FROM docker.bintray.io/jfrog/artifactory-pro:6.17.0

MAINTAINER jainishs@jfrog.com

# We download all the usual JDBC drivers available so we can configure them at runtime
RUN wget -O /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-5.1.41.jar https://jcenter.bintray.com/mysql/mysql-connector-java/5.1.41/mysql-connector-java-5.1.41.jar

COPY run.sh /runArtifactory.sh

# Dynamic configurations
COPY files/plugins/inactiveServerCleaner.groovy /tmp/inactiveServerCleaner.groovy
COPY server.xml /opt/jfrog/artifactory/tomcat/conf/server.xml
COPY binarystore.xml /tmp/binarystore.xml
COPY artifactory.config.xml /tmp/artifactory.config.xml

# Pre-Populated keys
RUN mkdir -p /var/opt/jfrog/artifactory/access/etc/keys/ && \
    mkdir -p /var/opt/jfrog/artifactory/etc/security/
ADD files/access/etc/keys/private.key /var/opt/jfrog/artifactory/access/etc/keys/private.key
ADD files/access/etc/keys/root.crt /var/opt/jfrog/artifactory/access/etc/keys/root.crt
ADD files/security/communication.key /var/opt/jfrog/artifactory/communication.key

ENTRYPOINT /runArtifactory.sh
