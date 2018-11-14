FROM docker.bintray.io/jfrog/artifactory-pro:6.5.8

LABEL MAINTAINER jainishs@jfrog.com

# We download all the usual JDBC drivers available so we can configure them at runtime
RUN curl -L -o  /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar
#RUN apt-get update && apt-get install -y dnsutils

COPY run.sh /runArtifactory.sh

# Dynamic configurations
COPY --chown=artifactory:artifactory files/plugins/inactiveServerCleaner.groovy /tmp/inactiveServerCleaner.groovy
COPY --chown=artifactory:artifactory server.xml /opt/jfrog/artifactory/tomcat/conf/server.xml
COPY --chown=artifactory:artifactory binarystore.xml /tmp/binarystore.xml
COPY --chown=artifactory:artifactory artifactory.config.xml /tmp/artifactory.config.xml

# Pre-Populated keys
RUN mkdir -p /var/opt/jfrog/artifactory/access/etc/keys/ /var/opt/jfrog/artifactory/etc/security/
COPY --chown=artifactory:artifactory files/access/etc/keys/private.key /var/opt/jfrog/artifactory/access/etc/keys/private.key
COPY --chown=artifactory:artifactory files/access/etc/keys/root.crt /var/opt/jfrog/artifactory/access/etc/keys/root.crt
COPY --chown=artifactory:artifactory files/security/communication.key /var/opt/jfrog/artifactory/communication.key

# Expose HA Port
EXPOSE 8081 10042

ENTRYPOINT /runArtifactory.sh
