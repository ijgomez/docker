# Stack01

Descripción: Stack compuesto por `postgres`, `wildfly` y `apache`. Apache actúa como reverse proxy hacia WildFly.

Ver la documentación general del repositorio en `../README.md`.

**Requisitos**
- Docker y Docker Compose (v1 o v2).

**Contenido del stack**
- `postgres` (imagen `postgres:14`) — puerto `5432:5432` — volumen `postgres_data:/var/lib/postgresql/data`.
- `wildfly` (build en `./wildfly`) — puertos `8080:8080` y `9990:9990`.
- `apache` (imagen `httpd:2.4`) — puerto `80:80` — monta `./apache/httpd.conf` que proxifica hacia WildFly.

**Comandos rápidos**
- Levantar el stack:

```bash
./start.sh
# o desde la raíz:
docker compose -f stack01/docker-compose.yml up -d --build
```

- Parar el stack:

```bash
./stop.sh
# o
docker compose -f stack01/docker-compose.yml down
```

- Reiniciar sólo Apache (después de cambiar `httpd.conf`):

```bash
cd stack01 && docker compose restart apache
```

**Puertos**
- Apache (frontend): `http://localhost:80` → proxifica a WildFly.
- WildFly (app): `http://localhost:8080`.
- WildFly (management): `http://localhost:9990`.
- Postgres: `localhost:5432`.

**Archivos importantes**
- `docker-compose.yml` — definición del stack.
- `apache/httpd.conf` — configuración del proxy hacia WildFly.
- `start.sh`, `stop.sh` — scripts convenientes que detectan `docker compose` o `docker-compose`.

**Cómo contribuir / desarrollo**
- Código de la aplicación en WildFly:
  - Modifica la fuente en el directorio que alimenta el `Dockerfile` de `wildfly` (revisa `stack01/wildfly`).
  - Reconstruye sólo `wildfly` tras cambios:

```bash
docker compose -f stack01/docker-compose.yml up -d --build wildfly
```

- Cambios en Apache:
  - Edita `stack01/apache/httpd.conf` y luego reinicia `apache`:

```bash
cd stack01 && docker compose restart apache
```

- Base de datos (esquema / datos iniciales): sigue las instrucciones del apartado siguiente.

**Ejemplo: desplegar datos iniciales en PostgreSQL**
Aquí hay dos métodos sencillos para cargar datos iniciales en la base de datos `appdb` creada por el servicio `postgres`.

1) Usar un archivo SQL desde el host (rápido):

```bash
cat > init-data.sql <<'SQL'
CREATE TABLE example (
  id serial PRIMARY KEY,
  name text NOT NULL
);

INSERT INTO example (name) VALUES ('alpha'), ('bravo');
SQL

# Ejecutar (desde la raíz del repo o donde esté el archivo):
docker exec -i postgres psql -U appuser -d appdb < init-data.sql
```

2) Montar scripts en la inicialización de Postgres (se ejecutan sólo la primera vez):
- Crea un directorio `stack01/initdb` y coloca allí `01-init.sql` con tus DDL/DML.
- Modifica temporalmente `docker-compose.yml` para montar `./initdb` en `/docker-entrypoint-initdb.d` del contenedor `postgres` (esto sólo hace efecto si el volumen `postgres_data` está vacío — es decir, en la primera inicialización).

Ejemplo de mount (fragmento):

```yaml
  postgres:
    image: postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./initdb:/docker-entrypoint-initdb.d:ro
```

Después, `docker compose up` ejecutará los scripts en `/docker-entrypoint-initdb.d` la primera vez que el contenedor crea la base de datos.

**Depuración y logs**
- Ver logs de cada contenedor:

```bash
docker logs -f postgres
docker logs -f wildfly
docker logs -f apache
```

- Si necesitas entrar a la base de datos para comprobar tablas:

```bash
docker exec -it postgres psql -U appuser -d appdb
```

**Buenas prácticas**
- No borres el volumen `postgres_data` si quieres conservar datos; para reiniciar con datos limpios, elimina el volumen explícitamente (y haz backup antes):

```bash
docker compose -f stack01/docker-compose.yml down
docker volume rm docker_postgres_data || true
```

- Mantén los scripts de inicialización en `stack01/initdb/` y anótalos en el control de versiones sólo si son idempotentes o seguros para re-ejecución.

Si quieres, puedo añadir un ejemplo `stack01/initdb/01-init.sql` en el repositorio y ajustar el `docker-compose.yml` para mostrar cómo se monta; dime si quieres que lo genere ahora.
