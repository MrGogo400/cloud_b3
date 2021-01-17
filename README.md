# TP1 Prise en main de Docker
Simon Laborde
Hugo Marques
Thomas Dumont

## I. Prise en main
### 1. Lancer des conteneurs

* Lister les conteneurs actifs, et mettre en évidence le conteneur lancé sur le sleep :
    ```
    [centos@localhost ~]$ docker ps -a
    CONTAINER ID        IMAGE               COMMAND              CREATED              STATUS              PORTS                NAMES
    97c6bd9d6fcd        alpine              "sleep 9999"         7 seconds ago        Up 6 seconds                             confident_einstein
    ```
    
* Montrer que le conteneur utilise :

    * des utilisateurs système différents :
    ```
    / # awk -F: '{ print $1}' /etc/passwd
    root
    bin
    daemon
    adm
    lp
    sync
    shutdown
    halt
    mail
    news
    uucp
    operator
    man
    postmaster
    cron
    ftp
    sshd
    at
    squid
    xfs
    games
    cyrus
    vpopmail
    ntp
    smmsp
    guest
    nobody
    ```


    * Des cartes réseau différentes :
    ```
    / # ifconfig
    eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:03  
              inet addr:172.17.0.3  Bcast:0.0.0.0  Mask:255.255.0.0
              inet6 addr: fe80::42:acff:fe11:3/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:8 errors:0 dropped:0 overruns:0 frame:0
              TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:0 
              RX bytes:656 (656.0 B)  TX bytes:656 (656.0 B)

    lo        Link encap:Local Loopback  
              inet addr:127.0.0.1  Mask:255.0.0.0
              inet6 addr: ::1/128 Scope:Host
              UP LOOPBACK RUNNING  MTU:65536  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
    ```
    
    * Une arborescence de processus différente :
    ```
    PID  PPID USER     STAT   VSZ %VSZ CPU %CPU COMMAND
    8     0 root     S     1636   0%   1   0% sh
   60     8 root     R     1572   0%   0   0% top
    1     0 root     S     1560   0%   1   0% sleep 9999

    ```
    
    * Des points de montage différents :
    ```
    / # df
    Filesystem           1K-blocks      Used Available Use% Mounted on
    overlay               29128812   1865016  27263796   6% /
    tmpfs                  4004424         0   4004424   0% /dev
    tmpfs                  4004424         0   4004424   0% /sys/fs/cgroup
    /dev/mapper/centos-root
                          29128812   1865016  27263796   6% /etc/resolv.conf
    /dev/mapper/centos-root
                          29128812   1865016  27263796   6% /etc/hostname
    /dev/mapper/centos-root
                          29128812   1865016  27263796   6% /etc/hosts
    shm                      65536         0     65536   0% /dev/shm
    /dev/mapper/centos-root
                          29128812   1865016  27263796   6% /run/secrets
    tmpfs                  4004424         0   4004424   0% /proc/acpi
    tmpfs                  4004424         0   4004424   0% /proc/kcore
    tmpfs                  4004424         0   4004424   0% /proc/keys
    tmpfs                  4004424         0   4004424   0% /proc/timer_list
    tmpfs                  4004424         0   4004424   0% /proc/timer_stats
    tmpfs                  4004424         0   4004424   0% /proc/sched_debug
    tmpfs                  4004424         0   4004424   0% /proc/scsi
    tmpfs                  4004424         0   4004424   0% /sys/firmware
    ```
    
    * Détruire le conteneur :
    ```
    [centos@localhost ~]$ docker ps -a
    CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                       PORTS                NAMES
    97c6bd9d6fcd        alpine              "sleep 9999"             38 minutes ago      Up 38 minutes                                     confident_einstein

    [centos@localhost ~]$ docker stop 97 && docker rm 97
    97
    97
    ```
    
* Lancer un conteneur NGINX :
`docker run --name basic_nginx --rm -d -p 80:80 nginx`
    
    
### 2. Gestion d'images

* Récupérer une image de Apache en version 2.2 : 
```shell=
[centos@localhost pythonwebserver]$ docker pull httpd:2.2
[centos@localhost pythonwebserver]$ docker image list
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
python-web              latest              0f2d7c57344c        28 minutes ago      50.7 MB
<none>                  <none>              f06044611ae4        29 minutes ago      50.7 MB
<none>                  <none>              c700a2acf6dc        32 minutes ago      50.7 MB
<none>                  <none>              87e2a3436cba        35 minutes ago      50.7 MB
<none>                  <none>              21183f5e2a00        36 minutes ago      50.7 MB
<none>                  <none>              b2bdd8bcebe2        41 minutes ago      50.7 MB
docker.io/alpine        latest              389fef711851        3 weeks ago         5.58 MB
docker.io/nginx         latest              ae2feff98a0c        3 weeks ago         133 MB
docker.io/hello-world   latest              bf756fb1ae65        12 months ago       13.3 kB
docker.io/httpd         2.2                 e06c3dbbfe23        2 years ago         171 MB
```


* Créer une image qui lance un serveur web python.

index.html :

```shell=
[centos@localhost pythonwebserver]$ cat index.html 
<H1>COUCOU</H1>
```
Dockerfile :

```dockerfile=
FROM alpine:latest
RUN apk add python3
EXPOSE 8888:8888
WORKDIR /http/webserver/
COPY index.html .
CMD ["python3", "-m", "http.server", "8888"]
```

docker build : 

```shell=
[centos@localhost pythonwebserver]$ docker build -t python-web .
Sending build context to Docker daemon 3.072 kB
Step 1/7 : FROM alpine:latest
 ---> 389fef711851
Step 2/7 : RUN apk add python3
 ---> Using cache
 ---> 1baf0b550a1c
Step 3/7 : EXPOSE 8888:8888
 ---> Using cache
 ---> cfad39013ae5
Step 4/7 : WORKDIR /http/webserver/
 ---> Using cache
 ---> 188f90b4d0d4
Step 5/7 : COPY index.html .
 ---> Using cache
 ---> 86bfe68b9bb9
Step 6/7 : CMD python -v
 ---> Using cache
 ---> 0175ead4bb38
Step 7/7 : CMD python3 -m http.server 8888
 ---> Using cache
 ---> 0f2d7c57344c
Successfully built 0f2d7c57344c
```

* Lancer le conteneur et accéder au serveur web du conteneur depuis votre PC :

```shell=
[centos@localhost pythonwebserver]$ docker run -dp 7777:8888 python-web
4bc888d90b71b468b72ec82b0bfb0976ab02d4b8abf67027e6f7ee026e6b8961
```

```shell=
hugo@DESKTOP-RBJLQA7:~$ curl 192.168.0.10:7777
<H1>COUCOU</H1> 
```

* utiliser l'option -v de docker run :

```shell=
[centos@localhost pythonwebserver]$ docker run -d -v /home/centos/pythonwebserver/:/http/webserver python-web
f0add076885ec05189e3dc094329fa7c341a439aa199d151380c078532900a3a
```

### 3. Manipulation du démon docker

* Modifier la configuration du démon Docker :

    * Trouvez le path du socket UNIX utilisé par défaut (c'est un fichier docker.sock)
    ```shell=
    [centos@localhost pythonwebserver]$ sudo find / -name "docker.sock"
    /run/docker.sock
    ```
    
    * Utiliser un socket TCP (port TCP) à la place : 
    ```shell=
    [centos@localhost ~]$ cat /etc/docker/daemon.json
    {
    "hosts": ["tcp://192.168.0.10:2375"]
    }
    ```
    * Prouver que ça fonctionne en manipulant le démon Docker à travers le réseau (depuis une autre machine) :
```shell=
~> sudo docker -H 192.168.0.10:2375 ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```shell=
akhadimer@Machinator3000:~$ sudo docker -H 192.168.0.10:2375 ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

* Modifier l'emplacement des données Docker :

```shell=
[centos@localhost ~]$ cat /etc/docker/daemon.json
{
"data-root": "/data/docker"
}
```

```shell=
[centos@localhost ~]$ sudo ls /data/docker/
buildkit  containers  image  network  overlay2  plugins  runtimes  swarm  tmp  trust  volumes
```
* Modifier le OOM score du démon Docker

```shell=
[centos@localhost ~]$ sudo cat /etc/docker/daemon.json
{
"data-root": "/data/docker",
"oom-score-adjust": -1000
}
```
```shell=
[centos@localhost ~]$ ps -ef | grep docker
root      5134     1  0 17:07 ?        00:00:00 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
centos    5455 25319  2 17:10 pts/4    00:00:00 vim docker-compose-v1.yml
centos    5459  3760  0 17:10 pts/3    00:00:00 grep --color=auto docker
[centos@localhost ~]$ cat /proc/5134/oom_score_adj
-1000
```

Nous avons choisi -1000 car plus la valeur est négative, moins le processus a de chance de ce faire kill par le "OOM Killer"

## II. docker-compose


### Write your own :

🌞 Ecrire un docker-compose-v1.yml qui permet de :


```dockerfile=
version: "3.3"

services:
  server:
    build: ./python-web
    networks:
      python-net:
        aliases:
          - python-web
    ports:
      - "80:8888"

networks:
  python-net:
```

🌞 Ajouter un deuxième conteneur docker-compose-v2.yml


```dockerfile=
version: "3.3"

services:
  reverse-proxy:
    image: nginx
    volumes:
      - ./nginx/conf/nginx.conf:/etc/nginx/conf.d/nginx.conf
      - ./nginx/certs/:/certs/
    networks:
      INTERNET:
        aliases:
          - reverse
    depends_on:
      - python-web
    ports:
      - 443:443
  python-web:
    build: ./webserver
    networks:
      INTERNET:
        aliases:
          - python

networks:
  INTERNET:
```

### Conteneuriser une application donnée

🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞🌞

```dockerfile=
version: "3.3"

services:
  db:
    image: redis
    networks:
      INTERNET:
        aliases:
          - db
  reverse-proxy:
    image: nginx
    volumes:
      - ./nginx/conf.d/nginx.conf:/etc/nginx/conf.d/nginx.conf
      - ./nginx/certs/:/certs/
    networks:
      INTERNET:
        aliases:
          - reverse
    depends_on:
      - app
    ports:
      - 443:443
  app:
    build: ./webserver
    networks:
      INTERNET:
        aliases:
          - python

networks:
```
