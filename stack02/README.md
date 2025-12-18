## stack02

Stack de ejemplo que contiene:

- `apache` (httpd 2.4) — actúa como reverse-proxy hacia WildFly
- `wildfly` (WildFly 11.0.0.Final) — ejecutada con Java 11 (Eclipse Temurin)
- `elasticsearch` (Elasticsearch 7.6.2) — configuración para entorno de desarrollo (single-node)

## Requisitos

- Docker y Docker Compose

## Levantar el stack

Desde el directorio `stack02` ejecuta:

```bash
# reconstruye la imagen de WildFly y levanta todos los servicios
docker compose up -d --build
```

Accesos:

- Apache: http://localhost:80 (proxy a WildFly)
- WildFly: http://localhost:8080
- Elasticsearch: http://localhost:9200

## Servicios definidos

Aquí tienes un resumen de los servicios que define `docker-compose.yml` en este stack:

- `apache`:
	- Imagen: `httpd:2.4` (configuración en `stack02/apache/httpd.conf`).
	- Función: reverse-proxy hacia `wildfly` en `http://wildfly:8080`.
	- Puertos: `80` expuesto en el host.

- `wildfly`:
	- Build: `./wildfly` (`stack02/wildfly/Dockerfile`).
	- Versión: WildFly 11.0.0.Final sobre Java 11 (Eclipse Temurin).
	- Puertos: `8080` (app) y `9990` (management).
	- Volumen: `wildfly_data` montado en `/opt/wildfly/standalone` para persistencia de configuración/temporal/logs.

- `elasticsearch`:
	- Imagen: `docker.elastic.co/elasticsearch/elasticsearch:7.6.2`.
	- Configuración: `discovery.type=single-node` (modo desarrollo).
	- Variables: `ES_JAVA_OPTS=-Xms512m -Xmx512m` (ajustable).
	- Puertos: `9200` (HTTP) y `9300` (transport) expuestos en el host.
	- Volumen: `es_data` para almacenar los datos de Elasticsearch.

- `openldap`:
	- Imagen: `osixia/openldap:1.5.0`.
	- Función: servidor LDAP para directorios (configurado para entorno de desarrollo).
	- Variables importantes: `LDAP_ORGANISATION`, `LDAP_DOMAIN`, `LDAP_ADMIN_PASSWORD`, `LDAP_CONFIG_PASSWORD`. En este stack además se desactiva TLS (`LDAP_TLS=false`) y se evita el cambio de dueño en volúmenes (`DISABLE_CHOWN=true`) para compatibilidad con sistemas host.
	- Volúmenes: usa `ldap_data` (datos) y `ldap_config` (configuración), y carga archivos seed desde `./openldap/seed`.
	- Notas: por defecto no se exponen puertos LDAP en el host en este `docker-compose.yml`; si necesitas acceder desde el host añade un mapeo de puertos, por ejemplo `ports: - "389:389"`.

- `phpldapadmin`:
	- Imagen: `osixia/phpldapadmin:0.9.0`.
	- Función: interfaz web de administración para OpenLDAP (phpLDAPadmin).
	- Variables: `PHPLDAPADMIN_LDAP_HOSTS=openldap`, `PHPLDAPADMIN_HTTPS=false`.
	- Notas: por defecto no expone puertos al host en este compose. Para acceder desde el navegador añade un mapeo `ports: - "8081:80"` al servicio. Credenciales por defecto para entrer en el directorio: `cn=admin,dc=stack02,dc=local` / `adminpassword`.

Los volúmenes declarados en el Compose son `wildfly_data`, `es_data`, `ldap_data` y `ldap_config`.

Nota: el `docker-compose.yml` de este stack no usa la clave `version` (Docker Compose la ignora y la advertencia fue eliminada).

## Notas

- Elasticsearch se configura en modo `single-node` mediante `discovery.type=single-node` y se expone en los puertos 9200/9300 en el host.
- WildFly se construye desde `stack02/wildfly/Dockerfile`. Ajusta el Dockerfile si necesitas módulos adicionales.
- Los datos de Elasticsearch se almacenan en el volumen `es_data`.

Si quieres, puedo:
- añadir un `Dockerfile` más avanzado para WildFly con usuario no-root y entrypoint personalizado (similar al de `stack01`),
- añadir scripts `start.sh` / `stop.sh` para este stack, o
- levantar el stack ahora y comprobar que los servicios arrancan correctamente.

## Scripts incluidos

He añadido tres scripts convenientes en la raíz de `stack02` para controlar el stack sin teclear comandos largos:

- `start.sh`: Reconstruye (si hace falta) y arranca todos los servicios.
- `stop.sh`: Para y elimina los contenedores del stack (`docker compose down`).
- `rebuild.sh`: Reconstruye las imágenes (total o servicios específicos) y levanta los servicios.

Ejemplos de uso (ejecutar desde `stack02`):

```bash
./start.sh               # reconstruye y levanta todo el stack
./stop.sh                # para y elimina los contenedores del stack
./rebuild.sh             # reconstruye todas las imágenes y levanta
./rebuild.sh wildfly     # reconstruye y levanta solo el servicio 'wildfly'
```

Estas utilidades facilitan el flujo de trabajo local; dime si quieres que adapte sus flags o comportamiento.
