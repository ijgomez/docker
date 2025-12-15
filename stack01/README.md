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

**Comandos útiles**
- **Levantar el stack** (raíz):

```bash
./stack01/start.sh
# o
docker compose -f stack01/docker-compose.yml up -d --build
```

- **Reconstruir solo WildFly** (desarrollo):

```bash
cd stack01
docker compose up -d --build wildfly
```

- **Reiniciar Apache** (después de cambiar `httpd.conf`):

```bash
cd stack01 && docker compose restart apache
```

- **Reconstruir y levantar (script):**

```bash
./rebuild.sh        # reconstruye todo el stack y lo levanta
./rebuild.sh wildfly postgres  # reconstruye y levanta solo wildfly y postgres
```

- **Ver logs en tiempo real**:

```bash
docker logs -f wildfly
docker logs -f postgres
docker logs -f apache
```

- **Crear usuario admin (helper)**:

```bash
./stack01/wildfly/add-admin.sh -u admin -p 'MiPassSeguro123'
```

- **Forzar creación de admin con .env**:

1. Copia `stack01/.env.example` → `stack01/.env` y rellena valores.
2. Levanta el stack: `cd stack01 && docker compose up -d --build`

- **Listar módulos/driver dentro del contenedor WildFly**:

```bash
docker exec wildfly ls -la /opt/wildfly/modules/system/layers/base/org/postgresql/main
docker exec wildfly cat /opt/wildfly/modules/system/layers/base/org/postgresql/main/module.xml
```

- **Listar datasources y drivers (jboss-cli)**:

```bash
docker exec wildfly /opt/wildfly/bin/jboss-cli.sh --connect --commands="/subsystem=datasources:read-resource(recursive=true)"
```

**Comprobar datasource `PostgresDS` y probar conexión al pool**:

```bash
docker exec wildfly /opt/wildfly/bin/jboss-cli.sh --connect --commands="/subsystem=datasources/data-source=PostgresDS:read-resource(include-runtime=true)"
docker exec wildfly /opt/wildfly/bin/jboss-cli.sh --connect --commands="/subsystem=datasources/data-source=PostgresDS:test-connection-in-pool"
```

**Uso de Docker Secrets**

Esta sección explica cómo usar Docker Secrets (Swarm) para no almacenar contraseñas en texto plano.

1) Crear los secrets en el nodo manager de Swarm:

```bash
echo "apppass" | docker secret create postgres_password -
echo "MiPassSeguro123" | docker secret create wildfly_admin_password -
```

2) Ejemplo de fragmento `docker-compose.yml` (versión para Swarm / deploy) para declarar y usar los secrets:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:14
    secrets:
      - postgres_password
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      # NOTA: el contenedor oficial de Postgres no expone automáticamente
      # POSTGRES_PASSWORD desde un secret; puedes envolver el entrypoint
      # en una imagen propia que lea /run/secrets/postgres_password y exporte
      # POSTGRES_PASSWORD antes de invocar el entrypoint original.

  wildfly:
    image: stack01-wildfly:latest
    secrets:
      - wildfly_admin_password
    environment:
      WILDFLY_ADMIN_USER: admin
      # leer en el entrypoint desde /run/secrets/wildfly_admin_password

secrets:
  postgres_password:
    external: true
  wildfly_admin_password:
    external: true
```

3) Leer secrets desde los contenedores (recomendado comportamiento del `entrypoint`):

En `stack01/wildfly/entrypoint.sh` puedes añadir (o ya hacerlo) lógica para preferir valores desde archivos de secrets si existen. Ejemplo de snippet a añadir al inicio del `entrypoint`:

```bash
# si existe secret montado, preferir su valor
if [ -f "/run/secrets/wildfly_admin_password" ]; then
  export WILDFLY_ADMIN_PASS=$(cat /run/secrets/wildfly_admin_password)
fi
if [ -f "/run/secrets/postgres_password" ]; then
  export DB_PASS=$(cat /run/secrets/postgres_password)
fi
```

4) Postgres + secrets

El contenedor oficial de Postgres no convierte automáticamente un secret montado en `/run/secrets/...` a la variable `POSTGRES_PASSWORD`. Opciones:
- Crear una pequeña imagen derivada de `postgres:14` que en su `entrypoint` lea `/run/secrets/postgres_password` y exporte `POSTGRES_PASSWORD` antes de llamar al `docker-entrypoint.sh` original.
- Usar un init container / job externo que inyecte la contraseña (en entornos orquestados).

Ejemplo mínimo de `Dockerfile` wrapper para Postgres (opcional):

```dockerfile
FROM postgres:14
COPY docker-entrypoint-wrapper.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wrapper.sh"]
CMD ["postgres"]
```

Contenido sugerido para `docker-entrypoint-wrapper.sh`:

```bash
#!/bin/bash
set -e
if [ -f /run/secrets/postgres_password ]; then
  export POSTGRES_PASSWORD="$(cat /run/secrets/postgres_password)"
fi
exec docker-entrypoint.sh "$@"
```

5) Notas de seguridad
- No añadas archivos de secrets ni `.env` con credenciales al control de versiones.
- Usa `docker secret` con Swarm o una solución de secretos de tu orquestador (Kubernetes secrets, Vault, etc.).
- Asegura que los permisos de `/run/secrets/*` sólo permitan lectura al usuario necesario dentro del contenedor.

Si quieres, puedo:
- añadir automáticamente la lectura de `/run/secrets/*` al `entrypoint.sh` de WildFly (lo hago y commiteo), o
- generar la imagen wrapper para Postgres y actualizar `docker-compose.yml` para usarla.


**Buenas prácticas**
- No borres el volumen `postgres_data` si quieres conservar datos; para reiniciar con datos limpios, elimina el volumen explícitamente (y haz backup antes):

```bash
docker compose -f stack01/docker-compose.yml down
docker volume rm docker_postgres_data || true
```

- Mantén los scripts de inicialización en `stack01/initdb/` y anótalos en el control de versiones sólo si son idempotentes o seguros para re-ejecución.

Si quieres, puedo añadir un ejemplo `stack01/initdb/01-init.sql` en el repositorio y ajustar el `docker-compose.yml` para mostrar cómo se monta; dime si quieres que lo genere ahora.

**Recomendaciones**
- **No usar credenciales por defecto en producción**: evita mantener `WILDFLY_ADMIN_PASS` u otras contraseñas en texto plano dentro del repositorio. Usa variables de entorno en el host, un archivo `.env` no versionado o un gestor de secretos.
- **Usar secretos para entornos sensibles**: considera Docker Secrets, HashiCorp Vault, o el mecanismo de secrets de tu orquestador para almacenar credenciales.
- **Rotación y cambio de credenciales**: si necesitas cambiar la contraseña de administración, crea un nuevo usuario, transfiere permisos si aplica y elimina el antiguo; evita sobrescribir mgmt-users.properties manualmente.
- **Inicialización de la DB**: los scripts bajo `stack01/initdb/` se ejecutan sólo la primera vez que Postgres crea el volumen de datos; si quieres re-ejecutarlos borra el volumen `postgres_data` (haz backup antes).
- **Backups periódicos**: programa backups regulares de la base de datos (por ejemplo `pg_dump`) antes de eliminar volúmenes o hacer cambios destructivos.
- **Crear usuarios desde entorno**: el contenedor `wildfly` soporta crear un usuario de gestión al arrancar si defines `WILDFLY_ADMIN_USER` y `WILDFLY_ADMIN_PASS` en `docker-compose.yml` o en el entorno del host. Alternativamente usa el helper `stack01/wildfly/add-admin.sh`.
- **Evitar contraseñas en commits**: no añadas `WILDFLY_ADMIN_PASS` ni otras credenciales en commits; añade ejemplos comentados o usa valores por defecto no sensibles.
- **Recompilar WildFly tras cambios en la imagen**: si modificas `stack01/wildfly/Dockerfile` o `entrypoint.sh`, reconstruye la imagen:

```bash
cd stack01
docker compose up -d --build wildfly
```

- **Permisos y seguridad**: restringe el acceso a los puertos de administración (`9990`) en entornos públicos o configura reglas de firewall / proxy que permitan acceso sólo desde redes de administración.

Si quieres, añado una pequeña sección de ejemplo en `stack01/.env.example` con variables (sin valores reales) y documentamos cómo usar Docker Secrets; dime si lo genero y lo commito.

**Helper `add-admin.sh`**
`stack01/wildfly/add-admin.sh` es un script auxiliar para crear un usuario de administración en el contenedor `wildfly`.

Uso rápido:

```bash
# Generar interactivamente / preguntar usuario (por defecto 'admin') y generar contraseña
./stack01/wildfly/add-admin.sh

# Especificar usuario y contraseña en la misma línea
./stack01/wildfly/add-admin.sh -u admin -p 'MiPassSeguro123'
```

Qué hace:
- Ejecuta `docker exec -i wildfly /opt/wildfly/bin/add-user.sh -u <user> -p <pass> -s -e`.
- Imprime la contraseña si la genera automáticamente.

Alternativa: definir variables en `stack01/.env` o en el entorno y levantar `wildfly` para que el `entrypoint` añada el usuario al arrancar.

Ejemplo usando `.env` (poner valores reales en `stack01/.env`, no en el repo):

```bash
cd stack01
docker compose up -d --build
```

`docker-compose` recogerá las variables del archivo `.env` y el `entrypoint` de WildFly intentará crear el usuario si no existe.

He añadido `stack01/.env.example` como plantilla para tus variables de entorno; copia a `stack01/.env` y actualiza los valores.
