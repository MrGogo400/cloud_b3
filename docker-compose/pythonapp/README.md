
###koman sa fonktione : 

Les commandes à executer dans l'ordre dans la racine du projet : 

```
docker-compose build
```

*Cette commande build le Dockerfile*

```
docker-compose -f nomdufichier up
```

*Cette commande éxecute le docker-compose.yml qui lui va démarrer des conteneurs, on doit préciser le nom du fichier car notre fichier docker-compose possède un nom différent.*

Nom des fichiers : 

- **docker-compose-v1.yml**
- **docker-compose-v2.yml**


*Le -d signifie "detach" et nous permet de garder la main sur notre terminal*

```
docker-compose down
```

*Cette commande stop et supprime les containeurs executer par le docker-compose.yml*
