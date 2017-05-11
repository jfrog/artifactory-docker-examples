## MySQL installation guide for DC/OS

## Steps to set up MySQL using DC/OS CLI:

1. Create mysql-options.json with following values:
```
{
  "service": {
    "name": "mysql"
  },
  "mysql": {
    "cpus": 0.3,
    "mem": 512
  },
  "database": {
    "name": "artdb",
    "username": "jfrogdcos",
    "password": "jfrogdcos",
    "root_password": "root"
  },
  "storage": {
    "host_volume": "/tmp",
    "persistence": {
      "enable": false,
      "volume_size": 256,
      "external": {
        "enable": false,
        "volume_name": "mysql",
        "provider": "dvdi",
        "driver": "rexray"
      }
    }
  },
  "networking": {
    "port": 3306,
    "host_mode": true,
    "external_access": {
      "enable": false,
      "external_access_port": 13306
    }
  }
}
```

2. run command ```dcos package install --options=mysql-options.json mysql```

3. Make sure MySQL is running and is healthy by looking under the services tab in the DC/OS UI.

Bingo! Now you can install Artifactory Pro/Enterprise.
*[Here is guide to install Artifactory Pro in DC/OS](Artifactory-Pro.md)
