# TP2 : Orchestration de conteneurs et environnements flexibles
Simon Laborde
Hugo Marques
Thomas Dumont

## II. Mise en place de Docker Swarm
### 1. Setup

*  Créer votre cluster Swarm et faire que les 3 machines soient des managers :

```
[vagrant@node1 web-pip]$ docker node ls
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
tuxbb6kha541xpteeot1nw4rb *   node1      Ready     Active         Leader           20.10.2
s09vxpzqvx558jvd53d89vjkq     node2      Ready     Active         Reachable        20.10.2
k30m84swvyty34a2jtuxe9pke     node3      Ready     Active         Reachable        20.10.2
```





### 2. Une première application orchestrée

* "swarmiser" l'application Python du TP1 :

```
version: "3.7"

services:
  pyweb:
    image: it4_web
    ports:
      - "8888:8888"
    networks:
      pyweb:
        aliases:
          - "pyweb"
  redis:
    image: redis
    networks:
      pyweb:
        aliases:
          - "db"

networks:
  pyweb:
```

* Explorer l'application et les fonctionnalités de Swarm :

    * Port exposé :
    ```
    LISTEN     0      128          *:8888                     *:*                   users:(("docker-proxy",pid=28032,fd=4))
    ```
    
    * docker service scale :
        `docker service scale It4web_pyweb=2`
    * `curl 192.168.121.66:8888` :
        Une fois sur deux ça affiche`Host : 3a78b989e017` et l'autre fois `Host : 224594ca758c`
    * Trouver sur quels hôtes tournent les conteneurs lancés :
        ```
        [vagrant@node3 web-pip]$ docker service ps It4web_pyweb
        ID             NAME             IMAGE            NODE      DESIRED STATE   CURRENT STATE           ER
        ROR     PORTS
        oadi3y4h3bwv   It4web_pyweb.1   it4_web:latest   node3     Running         Running 6 minutes ago     

        r4e0wj6s8mk9   It4web_pyweb.2   it4_web:latest   node2     Running         Running 6 minutes ago 
        ```
        
        
        
# III. Construction de l'écosystème

### 1. Registre

**Déployer un registre Docker simple**

Déployez sur node1 avec une commande `docker stack` :
```
wget https://gitlab.com/it4lik/b3-cloud-2020/-/raw/master/tp/2/registry/docker-compose
sudo mkdir -p /data/registry/{data,certs,auth}
docker stack deploy -c docker-compose.yml registry
```

```
[vagrant@node1 registre]$ cat /etc/docker/daemon.json 
{
  "hosts": ["tcp://registry.b3:5000"],
  "insecure-registries" : ["registry.b3:5000"]
}
```

**Tester le registre et utiliser le registre :**

Build l'image contenant l'app Python sur un noeud, en la nommant correctement pour notre registre

```
[vagrant@node1 web-pip]$ docker build -t registry.b3:5000/python-web:latest .
Sending build context to Docker daemon   7.68kB
Step 1/5 : FROM python:3.7-slim
 ---> 36b080f01d18
Step 2/5 : COPY ./app /app
 ---> Using cache
 ---> d0e153c9d7bc
Step 3/5 : WORKDIR /app
 ---> Using cache
 ---> 24d0091096ad
Step 4/5 : RUN pip install -r /app/requirements
 ---> Using cache
 ---> bb6c87c12d7a
Step 5/5 : CMD [ "python3", "/app/app.py" ]
 ---> Using cache
 ---> 36a05ec1fd5e
Successfully built 36a05ec1fd5e
Successfully tagged registry.b3:5000/python-web:latest
```

Pousser l'image de l'application Python

```
[vagrant@node1 web-pip]docker push registry.b3:5000/python-web:latest
The push refers to repository [registry.b3:5000/python-web]
802919827711: Pushed 
6a89614e07d4: Pushed 
26f76510e607: Pushed 
537b30bfd2be: Pushed 
e31d27fd5816: Pushed 
477e7db04777: Pushed 
cb42413394c4: Pushed 
latest: digest: sha256:76ee8cc18b3cf11cbff659ff77edfb9f29a2c404e4eb21a0e263383cb1cc4f1a size: 1788
```

Adapter le docker-compose.yml de l'application Python pour utiliser l'image du registre

```
version: "3.7"

services:
  pyweb:
    image: registry.b3:5000/python-web:latest
    ports:
      - "8888:8888"
    networks:
      pyweb:
        aliases:
          - "pyweb"
  redis:
    image: redis
    networks:
      pyweb:
        aliases:
          - "db"

networks:
  pyweb:
```


### 2. Centraliser l'accès aux services

**Déployer une stack Traefik**

Nous allons créer un réseau qui sera dédier au Traefik

```
[vagrant@node1 ~]$ docker network ls
NETWORK ID     NAME                    DRIVER    SCOPE
v22e53bygwd6   It4web_pyweb            overlay   swarm
snt4ltac3p9c   It4web_pyweb_pyweb      overlay   swarm
e8800d5c8705   bridge                  bridge    local
01437f4755f5   docker_gwbridge         bridge    local
f4edc9e05dec   host                    host      local
is6ey5rzlt4v   ingress                 overlay   swarm
3781e9bbadc1   none                    null      local
mlii20w5kfkw   registry_default        overlay   swarm
xkgpqfvbclk3   test_stack_python-net   overlay   swarm
outby1x1kzcx   traefik                 overlay   swarm
```

* Modifier le fichier pour définir un nom de domaine :
``` 
- "traefik.http.routers.traefik.rule=Host(`traefik.local`)"
```

* Fichier hosts : 
```
[vagrant@node1 traefik]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 registry.b3
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.1.1 node1 node1
192.168.42.20   node2
192.168.42.30   node3 traefik.local
```

* Interface Web :

![](https://i.ibb.co/YQfVpJ6/screen-traefik.png)

**Passer l'application Web Python derrière Traefik**

Une fois le reverse-proxy up nous allons créer notre service et le placer derrière le traefik 

```dockerfile=
version: "3"

services:
  pyweb:
    image: registry.b3:5000/python-web:latest
    networks:
      traefik:
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.python-webapp.rule=Host(`it4.webapp`)"
        - "traefik.http.routers.python-webapp.entrypoints=web"
        - "traefik.http.services.python-webapp.loadbalancer.server.port=8888"
        - "traefik.http.routers.python-webapp-tls.rule=Host(`it4.webapp`)"  
        - "traefik.http.routers.python-webapp-tls.entrypoints=webtls"
        - "traefik.http.routers.python-webapp-tls.tls.certresolver=letsencryptresolver"
    
  redis:
    image: redis
    networks:
      traefik:
        aliases:
          - "db"

networks:
  traefik:
    external: true
```

Bam on le deploie 

```bash=
[vagrant@node1 web-pip]$ docker stack deploy --compose-file docker-compose.yml It4web                      
Creating service It4web_pyweb
Creating service It4web_redis
[vagrant@node1 web-pip]$ docker stack ls 
NAME       SERVICES   ORCHESTRATOR
It4web     2          Swarm
registry   1          Swarm
traefik    1          Swarm
```

### 3. Swarm Management WebUI

Il faudra donc modifier le docker-compose.yml fourni dans la doc :

```dockerfile=
version: '3.3'

services:
  app:
    image: swarmpit/swarmpit:latest
    environment:
      - SWARMPIT_DB=http://db:5984
      - SWARMPIT_INFLUXDB=http://influxdb:8086
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 60s
      timeout: 10s
      retries: 3
    networks:
      - net
      - traefik
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.swarmpit.rule=Host(`swarmpit.local`)"
        - "traefik.http.routers.swarmpit.entrypoints=web"
        - "traefik.http.services.swarmpit.loadbalancer.server.port=8080"
        - "traefik.http.routers.swarmpit-tls.rule=Host(`swarmpit.local`)"  
        - "traefik.http.routers.swarmpit-tls.entrypoints=webtls"
        - "traefik.http.routers.swarmpit-tls.tls.certresolver=letsencryptresolver"
      resources:
        limits:
          cpus: '0.50'
          memory: 1024M
        reservations:
          cpus: '0.25'
          memory: 512M
      placement:
        constraints:
          - node.role == manager

  db:
    image: couchdb:2.3.0
    volumes:
      - db-data:/opt/couchdb/data
    networks:
      - net
    deploy:
      resources:
        limits:
          cpus: '0.30'
          memory: 256M
        reservations:
          cpus: '0.15'
          memory: 128M

  influxdb:
    image: influxdb:1.7
    volumes:
      - influx-data:/var/lib/influxdb
    networks:
      - net
    deploy:
      resources:
        limits:
          cpus: '0.60'
          memory: 512M
        reservations:
          cpus: '0.30'
          memory: 128M

  agent:
    image: swarmpit/agent:latest
    environment:
      - DOCKER_API_VERSION=1.35
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - net
    deploy:
      mode: global
      labels:
        swarmpit.agent: 'true'
      resources:
        limits:
          cpus: '0.10'
          memory: 64M
        reservations:
          cpus: '0.05'
          memory: 32M

networks:
  net:
    driver: overlay
  traefik:
    external: true

volumes:
  db-data:
    driver: local
  influx-data:
    driver: local
```

### 4. Stockage S3

Pour le stockage un script va s'occuper de tout, il s'exécute dès le démarrage de la machine, le voici : 

**🌞 Préparer l'environnement :**

```bash=
#!/bin/bash
#set -xv

if [[ $HOSTNAME == "node3" ]]; then
    echo "Partionnement du Disque Numéro 1"
    fdisk /dev/vdb << EOF
    n
    p
    1
    
    
    t
    8E
    w
EOF
    echo "Partionnement du Disque Numéro 2"
    fdisk /dev/vdc << EOF
    n
    p
    1
    
    
    t
    8E
    w
EOF
    mkdir /minio /minio-2
    pvcreate /dev/vdb1
    pvcreate /dev/vdc1
    vgcreate node3-1 /dev/vdb1
    vgcreate node3-2 /dev/vdc1
    lvcreate -l 100%FREE node3-1 -n data
    lvcreate -l 100%FREE node3-2 -n data2
    mount /dev/node3-1/data /minio
    echo -e "$(blkid |grep $HOSTNAME--1 |awk -F" " '{print $2}'|tr -d '"') /minio\t\text4\tdefaults\t0 0" >> /etc/fstab
    mount /dev/node3-2/data2 /minio-2
    echo -e "$(blkid |grep $HOSTNAME--2 |awk -F" " '{print $2}'|tr -d '"') /minio-2\t\text4\tdefaults\t0 0" >> /etc/fstab

else
    echo "Partionnement du Disque"
    fdisk /dev/vdb << EOF
    n
    p
    1
    
    
    t
    8E
    w
EOF
    mkdir /minio
    pvcreate /dev/vdb1
    vgcreate ${HOSTNAME} /dev/vdb1
    lvcreate -l 100%FREE ${HOSTNAME} -n data
    mount /dev/${HOSTNAME}/data /minio
    echo -e "$(blkid |grep $HOSTNAME |awk -F" " '{print $2}'|tr -d '"') /minio\t\text4\tdefaults\t0 0" >> /etc/fstab
fi

echo "Fin du partitionnement"
```

J'ai choisi de prendre deux disque différent alors qu'un seul disque et deux virtual groupe aurait pu suffire. 

**🌞 Déployer Minio :**

```bash
docker node update --label-add minio1=true node1
docker node update --label-add minio2=true node2
docker node update --label-add minio3=true node3
docker node update --label-add minio4=true node3
```

**🌞 Déployer Minio (suite) :**

```dockerfile=
version: '3'

services:
  minio1:
    image: minio/minio:RELEASE.2021-01-16T02-19-44Z
    hostname: minio1
    volumes:
      - /minio:/export
    networks:
      - minio_distributed
      - traefik
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.minio1.rule=Host(`minio.local`)"
        - "traefik.http.routers.minio1.entrypoints=web"
        - "traefik.http.services.minio1.loadbalancer.server.port=9000"
        - "traefik.http.routers.minio1-tls.rule=Host(`minio.local`)"  
        - "traefik.http.routers.minio1-tls.entrypoints=webtls"
        - "traefik.http.routers.minio1-tls.tls.certresolver=letsencryptresolver"
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      placement:
        constraints:
          - node.labels.minio1==true
    environment:
        MINIO_ROOT_USER: juancarlos
        MINIO_ROOT_PASSWORD: qwerty123
    command: server http://minio{1...4}/export
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  minio2:
    image: minio/minio:RELEASE.2021-01-16T02-19-44Z
    hostname: minio2
    volumes:
      - /minio:/export
    networks:
      - minio_distributed
    deploy:
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      placement:
        constraints:
          - node.labels.minio2==true
    environment:
        MINIO_ROOT_USER: juancarlos
        MINIO_ROOT_PASSWORD: qwerty123
    command: server http://minio{1...4}/export
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  minio3:
    image: minio/minio:RELEASE.2021-01-16T02-19-44Z
    hostname: minio3
    volumes:
      - /minio:/export
    networks:
      - minio_distributed
    deploy:
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      placement:
        constraints:
          - node.labels.minio3==true
    environment:
        MINIO_ROOT_USER: juancarlos
        MINIO_ROOT_PASSWORD: qwerty123
    command: server http://minio{1...4}/export
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  minio4:
    image: minio/minio:RELEASE.2021-01-16T02-19-44Z
    hostname: minio4
    volumes:
      - /minio-2:/export
    networks:
      - minio_distributed
    deploy:
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      placement:
        constraints:
          - node.labels.minio4==true
    environment:
        MINIO_ROOT_USER: juancarlos
        MINIO_ROOT_PASSWORD: qwerty123
    command: server http://minio{1...4}/export
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

networks:
  minio_distributed:
    driver: overlay
  traefik:
    external: true
```

Il fonctionne sur navigateur.

**🌞 Tester Minio :**

On a pas réussi.
