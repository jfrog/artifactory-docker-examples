# Dockerfile for a primary node
FROM docker.bintray.io/jfrog/artifactory-pro:6.6.5

MAINTAINER jainishs@jfrog.com

# Will be filtered and copied in etc when first running
ADD artifactory.config.xml /tmp/artifactory.config.xml

# We download all the usual JDBC drivers available so we can
# configure them at runtime
# Depending on the URL
RUN curl -L -o /opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-5.1.38.jar https://bintray.com/artifact/download/bintray/jcenter/mysql/mysql-connector-java/5.1.38/mysql-connector-java-5.1.38.jar

# Copy the run script
COPY run.sh /runArtifactory.sh

# Still needed ?
COPY server.xml /opt/jfrog/artifactory/tomcat/conf/server.xml

# This should be mapped to a shared NFS mounted on the host
EXPOSE 8081 10042

ENTRYPOINT /runArtifactory.sh
