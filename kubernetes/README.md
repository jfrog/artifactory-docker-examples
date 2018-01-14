# Artifactory in Kubernetes examples
This directory has some examples for setting up Artifactory running in a Kubernetes cluster.
 
## Kubernetes
Kubernetes is an open-source system for orchestrating containerized applications. To learn more about Kubernetes, see details in the [Kubernetes](https://kubernetes.io/docs/) documentation.  
This page assumes you have prior knowledge of Kubernetes and have a working cluster to deploy in.

## Helm - a package manager for Kubernetes
The recommended way to deploy your applications to Kubernetes is using [Helm](https://helm.sh/) charts (packages).  
Artifactory Pro can be deployed and managed by the [Helm](https://helm.sh/) package manager (also [supported by Artifactory](https://github.com/JFrogDev/artifactory-user-plugins/tree/master/helm/helmRepoSupport))  
See the [helm/artifactory](helm/artifactory) directory for an example and usage.

## Kubectl
The examples here are defines and deployed using the `kubectl` command line tool. See more details in the [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) documentation.  
Also see a useful [cheat sheet](https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/) with a good summary of the useful commands and usage.

In these examples Kubernetes objects are defines as Yaml files, so applying them is a simple call to `kubectl apply` or `kubectl create`.
  
--- 
## Persistent Storage
For persistent storage, all volumes are mounted from the cluster's hosts or as Google disks.  
**NOTE:** The examples here use a simple [PersistentVolume](https://kubernetes.io/docs/user-guide/persistent-volumes/) and 
[PersistentVolumeClaim](https://kubernetes.io/docs/user-guide/persistent-volumes/) for example purposes. This setup should **NOT** be used for production! 
You should find your best matching [storage solution](https://kubernetes.io/docs/user-guide/volumes/) and use it.
 
---
## Database Driver
The databases used in these examples are PostgreSQL and MySQL.  
For Artifactory to communicate with the database, it needs the database driver in its Tomcat's lib directory.  

Artifactory Docker image comes with the PostgreSQL driver pre-loaded.

For MySQL, you should build your own Artifactory Docker image using the `Dockerfile.mysql` in this directory that already adds the driver.  
To build the image
```bash
# For MySQL
$ docker build -t ${YOUR_DOCKER_REGISTRY}/jfrog/artifactory-pro-mysql:${VERSION} -f Dockerfile.mysql .
```
This will build an image of artifactory-pro that includes the MySQL driver in it. Make sure to push it into your registry
```bash
# For MySQL
$ docker push ${YOUR_DOCKER_REGISTRY}/jfrog/artifactory-pro-mysql:${VERSION}
```
And edit the artifactory.yml to use this image.

#### Using Different Databases
Artifactory can run with other databases. For more details on supported databases and how to set them up for use with Artifactory, please refer to [Changing the Database](https://www.jfrog.com/confluence/display/RTF/Changing+the+Database) in the JFrog Artifactory Use Guide.

---
## Deploying your Artifactory to Kubernetes
The following describes the steps to do the actual deployment of the Artifactory and its services to Kubernetes.

### Memory and CPU resources
To have full control of the memory and cpu allocated to your applications,
it is recommended to set [resource requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) to all your pods.

All templates here include examples of such resources definitions. The provided are examples. You should tune them to your actual needs.

### Preparing other Resources
Need to create some Kubernetes resources that will be used by Nginx as SSL and Artifactory reverse proxy configuration

#### Docker registry secret
In case you built your own Artifactory image and pushed it to your private registry as suggested above, you might need to define a docker-registry secret to be used by Kubernetes to pull images
```bash
$ kubectl create secret docker-registry docker-reg-secret --docker-server=${YOUR_DOCKER_REGISTRY} --docker-username=${USER} --docker-password=${PASSWORD} --docker-email=you@domain.com
```
#### SSL secret
Create the SSL secret that will be used by the Nginx pod  
**NOTE:** These are self signed key and certificate for demo use only!
```bash
$ kubectl create secret tls art-tls --cert=../files/nginx/ssl/demo.pem --key=../files/nginx/ssl/demo.key
```
You can replace the key and certificate with your own files
```bash
$ kubectl create secret tls art-tls --cert=${PATH_TO_CERT}/myssl.pem --key=${PATH_TO_CERT}/myssl.key
```

### Deploying the applications
Now you are ready to create the applications in Kubernetes.  
The following sequence deploys
- **PostgreSQL** or **MySQL** database
- **Artifactory** Pro or HA
- **Nginx**

Note that the resources to use are already defined in the Yaml files.

**NOTE:** If running on [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/), you will need to deploy a simpler service (NodePort). See the differences in the code examples below.

### Artifactory Pro
#### Database (using PostgreSQL)
```bash
# PostgreSQL storage, pods and service
$ kubectl apply -f postgresql-storage.yml
$ kubectl apply -f postgresql.yml
```

#### Artifactory
```bash
# Artifactory storage, pods and service
$ kubectl apply -f artifactory-storage.yml
$ kubectl apply -f artifactory.yml
```

#### Nginx
```bash
# Nginx storage and deployment
$ kubectl apply -f nginx-storage.yml
$ kubectl apply -f nginx-deployment.yml

# Nginx service
# If running on a standard Kubernetes cluster
$ kubectl apply -f nginx-service.yml

# If running on Minikube
$ kubectl apply -f nginx-service-minikube.yml
```

Once done, you should be able to see the deployed pods and services
```bash
# Get pods and their status
$ kubectl get pods
NAME                                          READY     STATUS    RESTARTS   AGE
artifactory-k8s-deployment-1732455857-7w6gw   1/1       Running   0          31m
nginx-k8s-deployment-3171003233-q8gb2         1/1       Running   0          25m
postgresql-k8s-deployment-1240329637-25325    1/1       Running   0          33m

# Get services
# On a standard Kubernetes cluster
$ kubectl get services
NAME                     CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
artifactory              10.0.160.189   <nodes>       8081/TCP         31m
kubernetes               10.0.0.1       <none>        443/TCP          3d
nginx-k8s-service        10.0.26.194    59.156.13.6   80/TCP,443/TCP   25m
postgresql-k8s-service   10.0.172.76    <none>        5432/TCP         33m

# On Minikube
$ kubectl get services
NAME                     CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
artifactory              10.0.0.210   <nodes>       8081:32355/TCP               57m
kubernetes               10.0.0.1     <none>        443/TCP                      1h
nginx-k8s-service        10.0.0.113   <nodes>       80:30002/TCP,443:32600/TCP   48m
postgresql-k8s-service   10.0.0.165   <none>        5432/TCP                     1h

```

#### Accessing your Artifactory Pro
See [Accessing your Artifactory](#accessing-your-artifactory)

---

### Artifactory HA
#### Database (using MySQL)
```bash
$ kubectl apply -f mysql-storage.yml
$ kubectl apply -f mysql.yml
```

#### Artifactory storage  
Prepare the storage volumes. One for each node.
```bash
$ kubectl apply -f artifactory-ha-storage.yml
```

#### Prepare the binary storage configuration
Artifactory HA can be configured with various storage solutions.  
You can see more details in [Configuring the Filestore](https://www.jfrog.com/confluence/display/RTF/Configuring+the+Filestore).  
In thie examples, we deploy a ConfigMap with a simple file-system replication configuration (a `cache-fs` template).
```bash
$ kubectl apply -f artifactory-binarystore.yml
```

#### Artifactory Master Key
As of Artifactory 5.7.X and up, the joining of a node to an HA cluster is much simpler. All nodes need to share the same `Master Key` and database configuration.
Create the key in the following way:
```bash
$ openssl rand -hex 32
```
You should put the resulting value inside the files `artifactory-ha-node1.yml` and `artifactory-ha-node2.yml` as the value of `ARTIFACTORY_MASTER_KEY`.
The files currently have a default value set, but you should update them for a production deployment.

#### Artifactory HA nodes
Spin up the two nodes and the Kubernetes service
```bash
$ kubectl apply -f artifactory-ha-node1.yml
$ kubectl apply -f artifactory-ha-node2.yml
$ kubectl apply -f artifactory-ha-service.yml
```

#### Complete the Artifactory HA cluster setup
Once the nodes are running, you need to complete the setup by installing the licenses for the nodes.
You can see more details in [Artifactory HA setup](https://www.jfrog.com/confluence/display/RTF/HA+Installation+and+Setup).

Check that the primary node (artifactory-node1) is up and ready to work.
```bash
# Get the primary node pod name
$ ART_NODE1_POD_NAME=$(kubectl get pods | grep artifactory-ha-node1 | cut -d' ' -f1)

# Follow the log for artifactory-node1
$ kubectl logs -f ${ART_NODE1_POD_NAME}

# Wait for the following to appear in the log:
###########################################################
### Artifactory successfully started (23.275 seconds)   ###
###########################################################

```

#### Nginx
Setup the Nginx that is used for load balancing, reverse proxy and SSL handling.

**NOTE:** Make sure to have the SSL secret create as [shown before](#ssl-secret)
```bash
# Storage and deployment
$ kubectl apply -f nginx-storage.yml
$ kubectl apply -f nginx-deployment.yml

# Service
# If running on a standard Kubernetes cluster
$ kubectl apply -f nginx-service.yml

# If running on Minikube
$ kubectl apply -f nginx-service-minikube.yml
```

Once done, you should be able to see the deployed pods and services
```bash
# Get pods and their status (example output)
$ kubectl get pods
NAME                                    READY     STATUS    RESTARTS   AGE
artifactory-ha-node1-3776668781-fc3wq   1/1       Running   0          7m
artifactory-ha-node2-3265495874-cz6rj   1/1       Running   0          7m
mysql-k8s-deployment-4196928137-3s6tn   1/1       Running   0          7m
nginx-k8s-deployment-1544469967-bt5m1   1/1       Running   0          1m

# Get services (example output)
# On a standard Kubernetes cluster
$ kubectl get services
NAME                CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
artifactory-node1   10.0.0.159   <nodes>       8081:30690/TCP               8m
artifactory-node2   10.0.0.176   <nodes>       8081:30981/TCP               7m
kubernetes          10.0.0.1     <none>        443/TCP                      3d
mysql-k8s-service   10.0.0.17    <none>        3306/TCP                     8m
nginx-k8s-service   10.0.0.75    59.156.13.6   80:32094/TCP,443:30063/TCP   2m

# On Minikube
$ kubectl get services
NAME                CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
artifactory-node1   10.0.0.159   <nodes>       8081:30690/TCP               8m
artifactory-node2   10.0.0.176   <nodes>       8081:30981/TCP               7m
kubernetes          10.0.0.1     <none>        443/TCP                      3d
mysql-k8s-service   10.0.0.17    <none>        3306/TCP                     8m
nginx-k8s-service   10.0.0.75    <nodes>       80:30002/TCP,443:32600/TCP   2m

```

#### Adding more nodes
Adding more Artifactory nodes to your cluster is simple. Here is an example for adding **node3**
- Add another `PersistentVolumeClaim` section in `artifactory-ha-storage.yml`. Give it a new name: **artifactory-node3-claim**
- Copy `artifactory-ha-node2.yml` to `artifactory-ha-node3.yml`. Edit it and rename all **node2** to **node3**
- Deploy the new storage and node
```bash
$ kubectl apply -f artifactory-ha-storage.yml
$ kubectl apply -f artifactory-ha-node3.yml
```
Make sure you have the license needed to have the new node join and activated in the cluster.

---

### Accessing your Artifactory
Depending on your deployment type, you can now access Artifactory through its Nginx.

#### Standard Kubernetes
You can see the Nginx is exposed with a public IP of `59.156.13.6` on ports 80 and 443.  
Now just point your browser to **http://59.156.13.6/artifactory/** or **https://59.156.13.6/artifactory/**  

#### Minikube
You need to use the Minikube's IP with the assigned port like `192.168.99.100`.
You can get the Minikube IP with the command `minikube ip`.  
The assigned minikube ports can be seen in the output of `kubectl get services` as seen above (port 30002 -> 80 and port 32600 -> 443).

Now point your browser to **http://192.168.99.100:30002/artifactory/** or **https://192.168.99.100:32600/artifactory/**

**NOTE**: When using `https`, you might need to confirm trusting the certificate and that will redirect you back to
https://192.168.99.100/artifactory, resulting in an error. Just put the port **32600** again in the URL, refresh your page,
and Artifactory should now load properly.
