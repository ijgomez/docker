# Docker
Repository with several Docker stacks and examples.

## Stacks

### Stack01
- **Descripción**: Stack compuesto por `apache` (Apache actúa como reverse proxy hacia WildFly), `wildfly` y `postgres`.
- **Ubicación**: `stack01/`.

### Stack02
- **Descripción**: Stack compuesto por `apache` (Apache actúa como reverse proxy hacia WildFly), `wildfly`, `elasticsearch`, `openldap` y `phpldapadmin`.
- **Ubicación**: `stack02/`.

## Comandos útiles (Docker)

Aquí tienes comandos prácticos para gestionar builders, cachés e imágenes cuando trabajas con Docker y `buildx`:

- Listar builders de `buildx`:

```bash
docker buildx ls
```

- Eliminar un builder de `buildx` (o todos, según versión):

```bash
docker buildx rm <builder-name>
# o
docker buildx rm --all
```

- Limpiar la caché del builder:

```bash
docker builder prune -f
```

- Limpieza general de recursos no usados (ejemplos):

```bash
docker image prune -af         # elimina imágenes no referenciadas
docker container prune -f      # elimina contenedores parados
docker volume prune -f         # elimina volúmenes no usados
```

Usa estos comandos con precaución en entornos de producción: revisa qué vas a eliminar antes de ejecutar `-f`.

## Script de limpieza: `clean.sh`

He añadido un script conveniente en la raíz del repositorio llamado `clean.sh` que automatiza la limpieza de recursos Docker no usados.

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
