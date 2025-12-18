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
