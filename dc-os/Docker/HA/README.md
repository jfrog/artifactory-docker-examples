Steps to build docker images:

1. create files directory inside HA directory and copy all contents form  [files](../../../files) to it.


2. build docker image using docker build command.
    e.g ```docker build -t jfrog-int-docker-open-docker.bintray.io/art-dcos:ha .```