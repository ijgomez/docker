# Stack01

Stack de ejemplo que contiene:
- `apache` (Apache 2.4)
- `wildfly` (WildFly 11.0.0.Final)
- `postgres` (Postgres 14)

Ver la documentación general del repositorio en `../README.md`.

## Requisitos
- Docker y Docker Compose (v1 o v2).

## Levantar el stack

Desde el directorio `stack01` ejecuta:

```bash
docker compose up -d --build
o
./stack01/start.sh
```

## Accesos

- Apache: http://localhost (proxy a WildFly)
- WildFly: http://localhost:8080
- WildFly Management: http://localhost:9990

## Servicios definidos en el stack

Aquí tienes un resumen de los servicios que define `docker-compose.yml` en este stack:

- `apache`:
	- Imagen: `httpd:2.4` (configuración en `stack01/apache/httpd.conf`).
	- Función: reverse-proxy hacia `wildfly` en `http://wildfly:8080`.
	- Puertos: `80` expuesto en el host.

- `wildfly`:
	- Imagen: `stack01-wildfly:latest`.
	- Puertos: `8080` (app) y `9990` (management).
  - Volumen: `wildfly_data` montado en `/opt/wildfly/standalone` para persistencia de configuración/temporal/logs.
  - Credenciales (por defecto) para entrar en la consola de administración (management): `admin` / `Admin.1234`.

- `postgres`:
	- Imagen: `postgres:14`.

## Scripts

Hay tres scripts convenientes en la raíz de `stack01` para controlar el stack sin teclear comandos largos:

- `start.sh`: Reconstruye (si hace falta) y arranca todos los servicios.
- `stop.sh`: Para y elimina los contenedores del stack (`docker compose down`).
- `rebuild.sh`: Reconstruye las imágenes (total o servicios específicos) y levanta los servicios.
- `stack01/wildfly/add-admin.sh` es un script auxiliar para crear un usuario de administración en el contenedor `wildfly`.


Ejemplos de uso (ejecutar desde `stack01`):

```bash
./start.sh                    # reconstruye y levanta todo el stack
./stop.sh                     # para y elimina los contenedores del stack
./rebuild.sh                  # reconstruye todas las imágenes y levanta
./rebuild.sh wildfly          # reconstruye y levanta solo el servicio 'wildfly'
./rebuild.sh wildfly postgres # reconstruye y levanta solo wildfly y postgres
./start-containers.sh         # inicia todos los contenedores ya creados
./start-containers.sh wildfly # inicia solo el servicio wildfly (si existe)
./stop-containers.sh          # para todos los contenedores del stack (no los elimina)
./stop-containers.sh wildfly  # para solo wildfly

./stack01/wildfly/add-admin.sh                               # Generar interactivamente / preguntar usuario (por defecto 'admin') y generar contraseña
./stack01/wildfly/add-admin.sh -u admin -p 'MiPassSeguro123' # Especificar usuario y contraseña en la misma línea
```

Estas utilidades facilitan el flujo de trabajo local.

## Notas

- El `docker-compose.yml` de este stack no usa la clave `version`.
- WildFly se construye desde `stack01/wildfly/Dockerfile`. Ajusta el Dockerfile si necesitas módulos adicionales.
- Los datos de Postgres se almacenan en el volumen `postgres_data`.



### Base de Datos

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

##Ejecutar (desde la raíz del repo o donde esté el archivo):
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

Si necesitas entrar a la base de datos para comprobar tablas:

```bash
docker exec -it postgres psql -U appuser -d appdb
```

### Depuración y logs
- Ver logs de cada contenedor:

```bash
docker logs -f apache
docker logs -f wildfly
docker logs -f postgres
```

### Wildfly / JBoss CLI

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

- **Comprobar datasource `PostgresDS` y probar conexión al pool**:

```bash
docker exec wildfly /opt/wildfly/bin/jboss-cli.sh --connect --commands="/subsystem=datasources/data-source=PostgresDS:read-resource(include-runtime=true)"
docker exec wildfly /opt/wildfly/bin/jboss-cli.sh --connect --commands="/subsystem=datasources/data-source=PostgresDS:test-connection-in-pool"
```

- **Nuevo Usuario en WildFly**:
- Ejecuta `docker exec -i wildfly /opt/wildfly/bin/add-user.sh -u <user> -p <pass> -s -e`.
- Imprime la contraseña si la genera automáticamente.

### Uso de Docker Secrets

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



### Recomendaciones**
- **No usar credenciales por defecto en producción**: evita mantener `WILDFLY_ADMIN_PASS` u otras contraseñas en texto plano dentro del repositorio. Usa variables de entorno en el host, un archivo `.env` no versionado o un gestor de secretos.
- **Usar secretos para entornos sensibles**: considera Docker Secrets, HashiCorp Vault, o el mecanismo de secrets de tu orquestador para almacenar credenciales.
- **Rotación y cambio de credenciales**: si necesitas cambiar la contraseña de administración, crea un nuevo usuario, transfiere permisos si aplica y elimina el antiguo; evita sobrescribir mgmt-users.properties manualmente.
- **Inicialización de la DB**: los scripts bajo `stack01/initdb/` se ejecutan sólo la primera vez que Postgres crea el volumen de datos; si quieres re-ejecutarlos borra el volumen `postgres_data` (haz backup antes).
- **Backups periódicos**: programa backups regulares de la base de datos (por ejemplo `pg_dump`) antes de eliminar volúmenes o hacer cambios destructivos.
- **Crear usuarios desde entorno**: el contenedor `wildfly` soporta crear un usuario de gestión al arrancar si defines `WILDFLY_ADMIN_USER` y `WILDFLY_ADMIN_PASS` en `docker-compose.yml` o en el entorno del host. Alternativamente usa el helper `stack01/wildfly/add-admin.sh`.
- **Evitar contraseñas en commits**: no añadas `WILDFLY_ADMIN_PASS` ni otras credenciales en commits; añade ejemplos comentados o usa valores por defecto no sensibles.
- **Permisos y seguridad**: restringe el acceso a los puertos de administración (`9990`) en entornos públicos o configura reglas de firewall / proxy que permitan acceso sólo desde redes de administración.

### Enviroment variables

Alternativa: definir variables en `stack01/.env` o en el entorno y levantar `wildfly` para que el `entrypoint` añada el usuario al arrancar.

Ejemplo usando `.env` (poner valores reales en `stack01/.env`, no en el repo):

```bash
cd stack01
docker compose up -d --build
```

`docker-compose` recogerá las variables del archivo `.env` y el `entrypoint` de WildFly intentará crear el usuario si no existe.

He añadido `stack01/.env.example` como plantilla para tus variables de entorno; copia a `stack01/.env` y actualiza los valores.
