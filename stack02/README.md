# stack02

Stack de ejemplo que contiene:
- `apache` (Apache 2.4)
- `wildfly` (WildFly 11.0.0.Final)
- `elasticsearch` (Elasticsearch 7.6.2)
- `samba-ad` (Active Directory Domain Controller basado en Samba)
- `openldap` (OpenLDAP 1.5.0)
- `phpldapadmin` (phpLDAPadmin 0.9.0) - Opcional

## Requisitos

- Docker y Docker Compose

## Levantar el stack

Desde el directorio `stack02` ejecuta:

```bash
docker compose up -d --build
```

## Accesos

- Apache: http://localhost (proxy a WildFly y PhpLDAPAdmin)
- PhpLDAPAdmin  : http://localhost/ldapadmin
- WildFly: http://localhost:8080
- WildFly Management: http://localhost:9990
- Elasticsearch: http://localhost:9200
- OpenLDAP: ldap://localhost:5389 (LDAPS en 5636)
- Active Directory (Samba AD DC): ldap://localhost:389 (LDAPS en 636)

## Servicios definidos en el stack

Aquí tienes un resumen de los servicios que define `docker-compose.yml` en este stack:

- `apache`:
	- Imagen: `httpd:2.4` (configuración en `stack02/apache/httpd.conf`).
	- Función: reverse-proxy hacia `wildfly` en `http://wildfly:8080` y `phpldapadmin` en `http://phpldapadmin:80`.
	- Puertos: `80` expuesto en el host.

- `wildfly`:
	- Build: `./wildfly` (`stack02/wildfly/Dockerfile`).
	- Versión: WildFly 11.0.0.Final sobre Java 11 (Eclipse Temurin).
	- Puertos: `8080` (app) y `9990` (management).
	- Volumen: `wildfly_data` montado en `/opt/wildfly/standalone` para persistencia de configuración/temporal/logs.
    - Credenciales (por defecto) para entrar en la consola de administración: `admin` / `Admin.1234`.

- `elasticsearch`:
	- Imagen: `docker.elastic.co/elasticsearch/elasticsearch:7.6.2`.
	- Configuración: `discovery.type=single-node` (modo desarrollo).
	- Variables: `ES_JAVA_OPTS=-Xms512m -Xmx512m` (ajustable).
	- Puertos: `9200` (HTTP) y `9300` (transport) expuestos en el host.
	- Volumen: `es_data` para almacenar los datos de Elasticsearch.
    - **Nota**: configuración para entorno de desarrollo (single-node)

- `samba-ad`:
	- Imagen: `nowsci/samba-domain` (controlador de dominio Active Directory basado en Samba).
	- Dominio: `stack02.local`.
	- Credenciales: usuario `Administrator`, contraseña `${DOMAINPASS}` definida en `docker-compose.yml` (`Admin_Password_2025!`).
	- Puertos: `389` (LDAP) y `636` (LDAPS) expuestos en el host.
	- Volumen: `samba_data` para la base de datos del dominio.
	- Hostname del DC: `stack02-ad-local`.

- `openldap`:
	- Imagen: `osixia/openldap:1.5.0`.
	- Función: servidor LDAP para directorios (configurado para entorno de desarrollo).
	- Variables importantes: `LDAP_ORGANISATION`, `LDAP_DOMAIN`, `LDAP_ADMIN_PASSWORD`, `LDAP_CONFIG_PASSWORD`. En este stack además se desactiva TLS (`LDAP_TLS=false`) y se evita el cambio de dueño en volúmenes (`DISABLE_CHOWN=true`) para compatibilidad con sistemas host.
	- Volúmenes: usa `ldap_data` (datos) y `ldap_config` (configuración), y carga archivos seed desde `./openldap/seed`.
    - Puertos: `5389` (ldap) y `5636` (ldaps).
	- **Nota**: se usan puertos distintos a 389/636 para no colisionar con el AD.

- `phpldapadmin`:
	- Imagen: `osixia/phpldapadmin:0.9.0`.
	- Función: interfaz web de administración para OpenLDAP (phpLDAPadmin).
	- Variables: `PHPLDAPADMIN_LDAP_HOSTS=openldap`, `PHPLDAPADMIN_HTTPS=false`.
    - Puertos: No hay acceso directo, se utiliza la url `http://localhost/ldapadmin`.
	- Credenciales (por defecto) para entrar en el directorio: `cn=admin,dc=stack02,dc=local` / `adminpassword`.

## Scripts

Hay tres scripts convenientes en la raíz de `stack02` para controlar el stack sin teclear comandos largos:

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

Estas utilidades facilitan el flujo de trabajo local

## Notas

- El `docker-compose.yml` de este stack no usa la clave `version`.
- Elasticsearch se configura en modo `single-node` mediante `discovery.type=single-node` .
- WildFly se construye desde `stack02/wildfly/Dockerfile`. Ajusta el Dockerfile si necesitas módulos adicionales.
- Los datos de Elasticsearch se almacenan en el volumen `es_data`.

### Esquemas LDAP personalizados

Para añadir `objectClass` adicionales:
- `pkiUser` ya está incluido en el esquema `core` de OpenLDAP.
- `entrustUser` se carga como esquema personalizado de ejemplo.

Cómo está configurado en este stack:
- Se monta `stack02/openldap/schema` en el contenedor para bootstrap: `./openldap/schema:/container/service/slapd/assets/config/bootstrap/schema/custom:ro`.
- El LDIF `01-custom-classes.ldif` define `entrustUser` como clase auxiliar.
- Se aplicó en el servidor con `cn=config` y se añadieron las `objectClass` al entry deseado.
- El certificado es solo para desarrollo (self-signed). Si necesitas uno real, reemplaza el contenido en `seed.ldif` y recrea el contenedor.
