
### Artifactory in Swarm example

This directory contains an example for setting up Artifactory running in a Swarm cluster.
In this example Artifactory Pro runs on one leader, meaning three images will run on the leader:
**docker.bintray.io/jfrog/artifactory-pro, docker.bintray.io/jfrog/postgres, docker.bintray.io/jfrog/nginx-artifactory-pro**

** This example applies only for Linux machines and was tested upon Ubuntu 16.04       
   with Docker version 17.03.1-ce, build c6d412e **

## Swarm

A swarm is a cluster of one or more Docker Engines running in swarm mode.
See details in the official [Swarm](https://docs.docker.com/engine/swarm/) documentation.

## Artifactory Pro with PostgreSQL and Nginx for https support

	$ sudo ./prepareHostEnv.sh -t pro -c
    $ sudo docker swarm init
    $ docker stack deploy -c artifactory-pro.yml artifactory  
    
  
    



