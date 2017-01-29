# Artifactory Docker Compose Examples
This repository provides some examples that show different ways to run Artifactory with Docker Compose.  
For more detailed documentation on running Artifactory with Docker, please refer to [Running with Docker][1] in the JFrog Artifactory User Guide


## Docker and Docker Compose
To learn more about Docker and how to set it up, please refer to the [Docker][2] and [Docker Compose][3] documentation.  
 

## Artifactory Docker Images
Artifactory is available as different Docker images for:
- [Artifactory Pro](#artifactory-pro-and-ha)
- [Artifactory OSS](#artifactory-oss)

These images are available for download from [JFrog Bintray][5].


## Artifactory as Docker registry
To use Artifactory as a Docker registry, you should use one of the Artifactory Pro or HA examples that use **Nginx**.  
For more details on using Artifactory as a Docker registry, please refer to [using Artifactory as a Docker registry][10].
 

## Docker Compose Examples
To run any of the examples, you should execute:  
```bash
$ docker-compose -f <compose-file> <options>
```


### Docker Compose Control Commands
- Start  
```bash
$ sudo docker-compose -f <compose-file> -d up
```
- Stop  
```bash
$ sudo docker-compose -f <compose-file> stop
```
- Restart  
```bash
$ sudo docker-compose -f <compose-file> restart
```
- Status  
```bash
$ sudo docker-compose -f <compose-file> ps
```
- Logs  
```bash
$ sudo docker-compose -f <compose-file> logs
```
- Remove  
```bash
$ sudo docker-compose -f <compose-file> rm
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

To help with setting up of directories and files for Artifactory Pro and HA, there is a helper script [prepareHostEnv.sh][11] you should run.  
This script prepares the needed directories on the host and populates them with example files.
Get the usage by running it with `-h`
```bash
sudo ./prepareHostEnv.sh -h
```

---
### Database Driver
The database used in these examples is PostgreSQL. For Artifactory to communicate with the database, it needs the
database driver mounted into its Tomcat's lib directory.  
You need to download the PostgreSQL driver (jar file) from [PostgreSQL download page][6] to your home directory.  
Direct link to driver: [https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar][7]  
In all examples using PostgreSQL, the file is mounted like this:  
`~/postgresql-9.4.1212.jar:/opt/jfrog/artifactory/tomcat/lib/postgresql-9.4.1212.jar`

#### Using Different Databases
Artifactory can run with other databases. For more details on supported databases and how to set them up for use with Artifactory, please refer to [Changing the Database][8] in the JFrog Artifactory Use Guide.

---
### Examples
Below is a list of included examples. You are welcome to contribute.

**IMPORTANT:** The files under the `files` directory included in this repository are for example purposes only and should NOT be used for any production deployments!  

---
#### Artifactory Pro and HA
Artifactory Pro and HA require some more setup due to the built in support for simple and complex configurations.  


##### Artifactory Pro with PostgreSQL 
```bash
$ sudo ./prepareHostEnv.sh -t pro -c
$ sudo docker-compose -f examples/artifactory-pro-postgresql.yml up -d
```  
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Artifactory Pro exposed on port 80
- PostgreSQL database serving Artifactory   

Artifactory uses the PostgreSQL database running in another container.


##### Artifactory Pro with PostgreSQL and Nginx for https support
```bash
$ sudo ./prepareHostEnv.sh -t pro -c
$ sudo docker-compose -f examples/artifactory-pro-nginx-ssl.yml up -d
```  
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Nginx exposed on ports 80 and 443
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten][9]
- Artifactory Pro exposed on port 8081
- PostgreSQL database serving Artifactory   


##### Artifactory HA with PostgreSQL and Nginx for load balancing and https support
```bash
$ sudo ./prepareHostEnv.sh -t ha -c
$ sudo docker-compose -f examples/artifactory-ha.yml up -d
```  
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Nginx exposed on ports 80 and 443
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten][9]
  - Nginx is configured to load balance the two Artifactory instances
- Artifactory primary exposed on port 8081 using its own data storage
- Artifactory node exposed on port 8082 using its own data storage
- PostgreSQL database serving Artifactory  

Artifactory data is stored on a binary store provider and no shared NFS is needed.  
I this example, the HA nodes use their local storage and sync data between the nodes. 


##### Artifactory HA with PostgreSQL and Nginx for load balancing and https support with shared data storage (NFS)
```bash
$ sudo ./prepareHostEnv.sh -t ha-shared-data -c
$ sudo docker-compose -f examples/artifactory-ha-shared-data.yml up -d
```
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Nginx exposed on ports 80 and 443
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten][9]
  - Nginx is configured to load balance the two Artifactory instances
- Artifactory primary exposed on port 8081
- Artifactory node exposed on port 8082
- PostgreSQL database serving Artifactory

Artifactory data is shared on a common NFS mount.


---
#### Artifactory OSS

##### Artifactory OSS standalone with built in Derby database
```bash
$ sudo docker-compose -f examples/artifactory-oss.yml up -d
```
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Artifactory OSS exposed on port 80  

Artifactory uses the embedded DerbyDB database.


##### Artifactory OSS with PostgreSQL
```bash
$ sudo docker-compose -f examples/artifactory-oss-postgresql.yml up -d
```
**IMPORTANT:** Make sure to prepare the needed [storage for persistent data](#persistent-storage)!

This example starts the following containers

- Artifactory OSS exposed on port 80
- PostgreSQL database serving Artifactory   

Artifactory uses the PostgreSQL database running in another container.




[1]: https://www.jfrog.com/confluence/display/RTF/Running+with+Docker
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/compose/overview/
[4]: https://www.jfrog.com
[5]: https://bintray.com/jfrog
[6]: https://jdbc.postgresql.org/download.html
[7]: https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar
[8]: https://www.jfrog.com/confluence/display/RTF/Changing+the+Database
[9]: NginxSSL.md
[10]: https://www.jfrog.com/confluence/display/RTF/Docker+Registry
[11]: prepareHostEnv.sh
