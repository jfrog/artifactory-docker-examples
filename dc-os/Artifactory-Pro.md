##Artifactory-Pro Installation Guide for DC/OS

## To Set Up Artifactory HA in DC/OS following are prerequisites:
1. **Database (MySQL)**
2. **Artifactory Pro License**

## It requires min 1 Public Slave to install Artifactory Pro or Enterprise

*[Here is guide to install MySQL in DC/OS](install-mysql.md)

*[Go here to Get your Trial License](https://www.jfrog.com/artifactory/free-trial-mesosphere/)

*Steps to Install Artifactory Pro using DC/OS CLI.

1. create `artifactory-pro-options.json` file with following content:
```
{
  "service": {
    "name": "artifactory",
    "cpus": 2,
    "mem": 2048,
    "licenses": "$ARTIFACTORY_PRO_LICENSE",
    "host-volume": "/var/artifactory",
    "database": {
      "connection-string": "jdbc:mysql://mysql.marathon.mesos:3306/artdb?characterEncoding=UTF-8&elideSetAutoCommits=true",
      "user": "jfrogdcos",
      "password": "jfrogdcos"
    }
  },
  "pro": {
    "local-volumes": {},
    "external-volumes": {
      "enabled": false
    }
  },
  "high-availability": {
    "enabled": false,
    "secondary": {
      "enabled": false,
      "unique-nodes": true,
      "nodes": 1,
      "name": "artifactory"
    }
  }
}
```

####NOTE: Make sure you provide your Artifactory-Pro/Trial license in json file.

2. Run command to install artifactory pro ```dcos package install --options=artifactory-pro-option.json artifactory```

3. Make sure Artifactory is running and its healthy by looking at Marathon UI.

##NOW you are just one step away in accessing Artifactory

4. [Install Artifactory-lb by following this guide to access artifactory](install-artifactory-lb.md)
