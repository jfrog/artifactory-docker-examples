# Artifactory Docker Compose Examples
This directory provides some examples that show different ways to run Artifactory with Docker Compose.  
To learn more about Docker and how to set it up, please refer to the [Docker](https://docs.docker.com) and [Docker Compose](https://docs.docker.com/compose/overview/) documentation.  
 

## Artifactory Docker Images
Artifactory is available as different Docker images for:
- [Artifactory Pro](#artifactory-pro)
- [Artifactory OSS](#artifactory-oss)

These images are available for download from [JFrog Bintray](https://bintray.com/jfrog).

 

## Docker-Compose Usage
To run any of the examples, you should execute:  
```bash
$ docker-compose -f <compose-file> <options>
```


### Docker Compose Control Commands
**NOTE:** On **MAC OSX**, you should omit the `sudo` from all your `docker-compose` commands


- Start  
```bash
$ sudo docker-compose -f <compose-file> up -d  # Create and start containers
```
- Stop  
```bash
$ sudo docker-compose -f <compose-file> stop  # Stop services
```
- Restart  
```bash
$ sudo docker-compose -f <compose-file> restart # Restart services
```
- Status  
```bash
$ sudo docker-compose -f <compose-file> ps # List containers
```
- Logs  
```bash
$ sudo docker-compose -f <compose-file> logs # View output from containers
```
- Remove  
```bash
$ sudo docker-compose -f <compose-file> rm # Remove stopped containers
```
 
--- 
### Persistent Storage
For persistent storage, all volumes are mounted from the host.  
All examples default to the host's **/data** directory  
**IMPORTANT:** You should create the directories on the host before running `docker-compose`.
- Artifactory data: **/data/artifactory**
  - In the case of HA, you need to create a data directory for each node: **/data/artifactory/node1** and **/data/artifactory/node2**
  - In the case of HA with shared data storage, you need to create the shared data and backup directories: **/data/artifactory/ha** and **/data/artifactory/backup**
- PostgreSQL data: **/data/postgresql**
- NginX
  - Logs: **/data/nginx/log**
  - SSL: **/data/nginx/ssl**

To help with setting up of directories and files for Artifactory Pro and HA, there is a helper script [prepareHostEnv.sh](prepareHostEnv.sh) you should run.  
This script prepares the needed directories on the host and populates them with example files.
Get the usage by running it with `-h`
```bash
sudo ./prepareHostEnv.sh -h
```
After executing the script, the needed set of data directories for Artifactory Pro or HA will be created under **/data** (on Mac it defaults to **~/.artifactory**).  

---
### Database Driver
The database used in these examples is PostgreSQL.  
The PostgreSQL database driver comes pre-loaded into the Artifactory Docker image, but you can still use other databases without any conflicts. 

#### Using Different Databases
Artifactory can run with other databases. For more details on supported databases and how to set them up for use with Artifactory, please refer to [Changing the Database](https://www.jfrog.com/confluence/display/RTF/Changing+the+Database) in the JFrog Artifactory Use Guide.

---
# Docker Compose Examples
Below is a list of included examples. You are welcome to contribute.

**IMPORTANT:** The files under the `files` directory included in this repository are for example purposes only and should NOT be used for any production deployments ! 

---
## Artifactory Pro

#### Artifactory Pro with PostgreSQL and Nginx for Docker registry support
```bash
### Linux
$ sudo ./prepareHostEnv.sh -t pro -c
$ sudo docker-compose -f artifactory-pro.yml up -d
### MAC OSX
$ ./prepareHostEnv.sh -t pro -c
$ sed -i.bk "s,/data/,~/.artifactory/,g" artifactory-pro.yml #Backup the config file and changes the home directory to MAC OS default 
$ docker-compose -f artifactory-pro.yml up -d

```  

This example starts the following containers

- Nginx exposed on ports 80 (http) and 443 (https)
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten](NginxSSL.md)
- Artifactory Pro exposed on port 8081
- PostgreSQL database serving Artifactory exposed on port 5432 


#### Artifactory Pro with PostgreSQL only 
```bash
### Linux
$ sudo ./prepareHostEnv.sh -t pro -c
$ sudo docker-compose -f artifactory-pro-postgresql.yml up -d
### MAC OSX
$ ./prepareHostEnv.sh -t pro -c
$ sed -i.bk "s,/data/,~/.artifactory/,g" artifactory-pro-postgresql.yml
$ docker-compose -f artifactory-pro-postgresql.yml up -d
```  

This example starts the following containers

- Artifactory Pro exposed on port 80
- PostgreSQL database serving Artifactory exposed on port 5432  

Artifactory uses the PostgreSQL database running in another container.


#### Artifactory Pro with Derby and Nginx for Docker registry support
```bash
$ sudo ./prepareHostEnv.sh -t pro -c
$ sudo docker-compose -f artifactory-pro-nginx-derby.yml up -d
```  

This example starts the following containers

- Nginx exposed on ports 80 (http) and 443 (https)
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten](NginxSSL.md)
- Artifactory Pro exposed on port 8081  

Artifactory uses the embedded Derby as its database.

## Artifactory HA

#### Artifactory HA with PostgreSQL and Nginx for Docker registry and load balancing support
```bash
### Linux
$ sudo ./prepareHostEnv.sh -t ha -c
$ sudo docker-compose -f artifactory-ha.yml up -d

### MAC OSX
$ ./prepareHostEnv.sh -t ha -c
$ sed -i.bk "s,/data/,~/.artifactory/,g" artifactory-ha.yml
$ docker-compose -f artifactory-ha.yml up -d
```  

This example starts the following containers

- Nginx exposed on ports 80 (http) and 443 (https)
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten](NginxSSL.md)
  - Nginx is configured to load balance between the two Artifactory instances
- Artifactory primary exposed on port 8081 using its own data storage
- Artifactory node exposed on port 8082 using its own data storage
- PostgreSQL database serving Artifactory  

Artifactory data is stored on a binary store provider and no shared NFS is needed.  
In this example, the HA nodes use their local storage and sync data between the nodes. 

**NOTE:** You must complete the onboarding process to have a fully functional Artifactory HA cluster!

#### Artifactory HA with PostgreSQL and Nginx for Docker registry and load balancing support with shared data storage (NFS)
```bash
### Linux
$ sudo ./prepareHostEnv.sh -t ha-shared-data -c
$ sudo docker-compose -f artifactory-ha-shared-data.yml up -d

### MAC OSX
$ ./prepareHostEnv.sh -t ha-shared-data -c
$ sed -i.bk "s,/data/,~/.artifactory/,g" artifactory-ha-shared-data.yml
$ docker-compose -f artifactory-ha-shared-data.yml up -d
```

This example starts the following containers

- Nginx exposed on ports 80 (http) and 443 (https)
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten](NginxSSL.md)
  - Nginx is configured to load balance the two Artifactory instances
- Artifactory primary exposed on port 8081
- Artifactory node exposed on port 8082
- PostgreSQL database serving Artifactory

Artifactory data is shared on a common NFS mount.

**NOTE:** You must complete the onboarding process to have a fully functional Artifactory HA cluster!


---
### Artifactory OSS

#### Artifactory OSS standalone with built in Derby database
```bash
### Linux
$ sudo ./prepareHostEnv.sh -t oss -c
$ sudo docker-compose -f artifactory-oss.yml up -d
```
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Artifactory OSS exposed on port 80  

Artifactory uses the embedded DerbyDB database.


#### Artifactory OSS with PostgreSQL
```bash
### Linux
$ sudo ./prepareHostEnv.sh -t oss -c
$ sudo docker-compose -f artifactory-oss-postgresql.yml up -d
```
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Artifactory OSS exposed on port 80
- PostgreSQL database serving Artifactory   

Artifactory uses the PostgreSQL database running in another container.


