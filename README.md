# Artifactory Docker Compose Examples
This repository provides various examples for running Artifactory with Docker Compose.  
For the **Artifactory in Docker** documentation, go to the official [Artifactory in Docker][1] page.

## Docker and Docker Compose
See the official [Docker][2] and [Docker Compose][3] documentation on what Docker is and how to set it up.  
 
## Artifactory Docker images
Artifactory in Docker is released as two Docker images
- Artifactory OSS
- Artifactory Pro

You can find the images in [JFrog's Bintray][5] page.
 
## Docker Compose examples
To run any of the examples, you should execute:  
`$ docker-compose -f <compose-file> <options>`

### Docker Compose control commands
- Start  
`$ docker-compose -f <compose-file> -d up`
- Stop  
`$ docker-compose -f <compose-file> stop`
- Restart  
`$ docker-compose -f <compose-file> restart`
- Status  
`$ docker-compose -f <compose-file> ps`
- Logs  
`$ docker-compose -f <compose-file> logs`
- Remove  
`$ docker-compose -f <compose-file> rm`
 
 
### Storage
For persistent storage, all volumes are mounted from the host.  
All examples default to **/data/...**  
**IMPORTANT:** You should create the directories on the host before running `docker-compose`.
- Artifactory data is in **/data/artifactory**
- PostgreSQL storage is in **/data/postgresql**
- NginX configuration is in **/data/nginx**

### Database driver
The database used in these examples is PostgreSQL. In order for Artifactory to communicate with the database, it needs the
database driver mounted into its Tomcat's lib directory.  
You need to download the PostgreSQL driver (jar file) from [PostgreSQL download page][6] to your home directory.  
Direct link to driver: [https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar][7]  
In all examples using PostgreSQL, the file is mounted like this:  
`~/postgresql-9.4.1212.jar:/opt/jfrog/artifactory/tomcat/lib/postgresql-9.4.1212.jar`

#### Other databases
Artifactory can run with other databases. You can get more information on this in JFrog's [Artifactory Wiki pages][8]

### Examples
Here is a list of the included examples in this project. You are welcome to contribute.

#### Artifactory OSS standalone with built in Derby database
Compose file: `examples/artifactory-oss-standalone.yml`  
This example starts the following containers

- Artifactory OSS exposed on port 80  


#### Artifactory OSS with PostgreSQL
Compose file: `examples/artifactory-oss-postgresql.yml`  
This example starts the following containers

- Artifactory OSS exposed on port 80
- PostgreSQL database serving Artifactory   


#### Artifactory Pro with PostgreSQL 
Compose file: `examples/artifactory-pro-postgresql.yml`  
This example starts the following containers

- Artifactory Pro exposed on port 80
- PostgreSQL database serving Artifactory   


#### Artifactory Pro with PostgreSQL and Nginx for https support
Compose file: `examples/artifactory-pro-nginx-ssl.yml`  
This example starts the following containers

- Nginx exposed on ports 80 and 443
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten][9]
- Artifactory Pro exposed on port 8081
- PostgreSQL database serving Artifactory   


#### Artifactory HA with PostgreSQL and Nginx for load balancing and https support
Compose file: `examples/artifactory-ha-nginx-ssl.yml`  
This example starts the following containers

- Nginx exposed on ports 80 and 443
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten][9]
  - Nginx is configured to load balance the two Artifactory instances
- Artifactory primary exposed on port 8081
- Artifactory node exposed on port 8082
- PostgreSQL database serving Artifactory   


#### Artifactory HA with PostgreSQL and Nginx for load balancing and https support without shared data storage
Compose file: `examples/artifactory-ha-nginx-ssl-without-shared-data.yml`  
This example starts the following containers

- Nginx exposed on ports 80 and 443
  - You can disable port 80 in Nginx's configuration files
  - Nginx comes with self signed SSL certificates [that can be overwritten][9]
  - Nginx is configured to load balance the two Artifactory instances
- Artifactory primary exposed on port 8081 using its own data storage
- Artifactory node exposed on port 8082 using its own data storage
- PostgreSQL database serving Artifactory  





[1]: https://www.jfrog.com/confluence/display/RTF/Running+with+Docker
[2]: https://docs.docker.com/
[3]: https://docs.docker.com/compose/overview/
[4]: https://www.jfrog.com
[5]: https://bintray.com/jfrog
[6]: https://jdbc.postgresql.org/download.html
[7]: https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar
[8]: https://www.jfrog.com/confluence/display/RTF/Welcome+to+Artifactory
[9]: NginxSSL.md