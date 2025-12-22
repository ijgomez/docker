# Docker
Repository with several Docker stacks and examples.

## Stacks

### Stack01
- **Descripción**: Stack compuesto por `apache`, `wildfly` y `postgres`.
- **Ubicación**: `stack01/`.

### Stack02
- **Descripción**: Stack compuesto por `apache`, `wildfly`, `elasticsearch`, `openldap` , `samba-ad` y `phpldapadmin`.
- **Ubicación**: `stack02/`.

### Stack03
- **Descripción**: Stack compuesto por `apache`, `tomcat`, `elasticsearch` y `samba-ad` como Active Directory.
- **Ubicación**: `stack03/`.

### Stack04
- **Descripción**: Stack compuesto por `apache`, `tomcat`, `elasticsearch`, `samba-ad` y `mysql`.
- **Ubicación**: `stack04/`.

### Stack05
- **Descripción**: Stack compuesto por `nginx`, `tomcat`, `samba-ad` y un servidor `ftp` (`fauria/vsftpd`).
- **Ubicación**: `stack05/`.


## Script de limpieza: `clean.sh`

Script conveniente en la raíz del repositorio llamado `clean.sh` que automatiza la limpieza de recursos Docker no usados.

- **Ubicación:** `./clean.sh`
- **Propósito:** eliminar contenedores parados, imágenes huérfanas, redes y volúmenes no usados; limpiar cachés de build y `buildx`; y —si encuentra proyectos con `docker-compose.yml`/`docker-compose.yaml`— ejecutar `docker compose down --rmi all --volumes` en esos directorios para bajarlos limpiamente.
- **Flags:** `-y` ejecuta todo sin pedir confirmación interactiva.

Ejemplos de uso:

```bash
# ejecutar interactivamente (pregunta antes de borrar)
chmod +x clean.sh
./clean.sh

# ejecutar sin confirmaciones (útil en scripts CI locales)
./clean.sh -y
```

Comportamiento adicional y notas:

- El script muestra un resumen inicial (`docker system df`), detecta archivos `docker-compose.yml`/`docker-compose.yaml` hasta 4 niveles de profundidad y pregunta (salvo `-y`) si debe ejecutar `docker compose down --rmi all --volumes` en cada proyecto.
- Ejecuta `docker system prune -a --volumes -f`, `docker builder prune -af`, intenta eliminar builders `buildx` (`docker buildx rm --all`) y ejecuta prunes adicionales de imágenes, redes y volúmenes.
- Usa los comandos con precaución: en hosts con datos importantes no deseados, revisa `docker compose ls` y `docker system df` antes de borrar.
