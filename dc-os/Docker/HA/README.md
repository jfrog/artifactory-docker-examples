##Steps to build Artifactory HA docker images for DC/OS:

1. Create files directory inside HA directory and copy all contents form  [files](../../../files) to it.


2. Build docker image using docker build command.
    e.g ```docker build -t jfrog-int-docker-open-docker.bintray.io/art-dcos:ha .```

3. Deploy image in environment (e.g [Bintray](https://bintray.com/)) which is accessible by your DC/OS cluster.