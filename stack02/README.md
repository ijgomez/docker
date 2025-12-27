# stack02

Stack de ejemplo que contiene:
- `apache` (Apache 2.4)
- `wildfly` (WildFly 11.0.0.Final)
- `elasticsearch` (Elasticsearch 7.6.2)
- `samba-ad` (Active Directory Domain Controller basado en Samba)
- `openldap` (OpenLDAP 1.5.0)
- `phpldapadmin` (phpLDAPadmin 0.9.0) - Opcional

Ver la documentación general del repositorio en `../README.md`.

## Requisitos

- Docker y Docker Compose (v1 o v2).

## Levantar el stack

Desde el directorio `stack02` ejecuta:

```bash
docker compose up -d --build
```

## Accesos

### HTTP y HTTPS
- Apache HTTP: http://localhost (proxy a WildFly y PhpLDAPAdmin)
- Apache HTTPS: https://localhost
- PhpLDAPAdmin: http://localhost/ldapadmin o https://localhost/ldapadmin
- WildFly HTTP: http://localhost:8080
- WildFly HTTPS: https://localhost:8443
- WildFly Management: http://localhost:9990

### Otros servicios
- Elasticsearch: http://localhost:9200
- OpenLDAP: `ldap://localhost:5389` (LDAPS en 5636)
- Active Directory (Samba AD DC): `ldap://localhost:389` (LDAPS en 636)

## Servicios definidos en el stack

Aquí tienes un resumen de los servicios que define `docker-compose.yml` en este stack:

- `apache`:
	- Imagen: `httpd:2.4` (configuración en `stack02/apache/httpd.conf`).
	- Función: reverse-proxy hacia `wildfly` en `http://wildfly:8080` y `phpldapadmin` en `http://phpldapadmin:80`.
	- Puertos: `80` (HTTP) y `443` (HTTPS) expuestos en el host.
	- SSL: certificados autofirmados en `stack02/apache/certs/`.

- `wildfly`:
	- Build: `./wildfly` (`stack02/wildfly/Dockerfile`).
	- Versión: WildFly 11.0.0.Final sobre Java 11 (Eclipse Temurin).
	- Puertos: `8080` (HTTP), `8443` (HTTPS) y `9990` (management).
	- SSL: keystore en `stack02/wildfly/certs/wildfly.keystore`.
	- Volumen: `wildfly_data` montado en `/opt/wildfly/standalone` para persistencia de configuración/temporal/logs.
    - Credenciales (por defecto) para entrar en la consola de administración (management): `admin` / `Admin.1234`.

- `elasticsearch`:
	- Imagen: `docker.elastic.co/elasticsearch/elasticsearch:7.6.2`.
	- Configuración: `discovery.type=single-node` (modo desarrollo).
	- Variables: `ES_JAVA_OPTS=-Xms512m -Xmx512m` (ajustable).
	- Puertos: `9200` (HTTP) y `9300` (transport) expuestos en el host.
	- Volumen: `es_data` para almacenar los datos de Elasticsearch.
    - **Nota**: configuración para entorno de desarrollo (single-node)

- `samba-ad`:
	- Build: `./samba-ad` (Dockerfile personalizado basado en `nowsci/samba-domain`).
	- Dominio: `stack02.local`.
	- Credenciales: `administrator@stack02.local` / `Admin_Password_2025!` (variable para contraseña: `DOMAINPASS`).
	- Usuarios creados al arrancar: `Administrator` y los definidos en `samba-ad/users.csv` (`/var/log/create-users.log`).
	- Grupos creados al arrancar: definidos en `samba-ad/groups.csv` (`/var/log/create-groups.log`).
	- Puertos: `389` (LDAP) y `636` (LDAPS) expuestos en el host.
    - Requiere cifrado: usa StartTLS sobre ldap:`389` o ldaps:`636` (certificado autofirmado).
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

## Configuración SSL/HTTPS

Apache y WildFly están configurados para aceptar conexiones HTTPS además de HTTP usando certificados autofirmados que se generan automáticamente al construir las imágenes.

### Generación automática de certificados

Los certificados SSL se generan automáticamente durante la construcción de las imágenes Docker si no existen:

- **Apache**: Los certificados se generan en el primer arranque y se almacenan en un volumen Docker (`apache_certs`)
- **WildFly**: El keystore se genera en el primer arranque y se almacena en el volumen `wildfly_data`

No es necesario generar los certificados manualmente. Simplemente ejecuta:

```bash
./start.sh
# o
docker compose up -d --build
```

### Regenerar certificados

Si necesitas regenerar los certificados (por ejemplo, si han expirado):

1. Elimina los volúmenes que contienen los certificados:
   ```bash
   docker compose down -v
   ```

2. Reconstruye y reinicia los servicios:
   ```bash
   ./start.sh
   ```

Los certificados se generarán automáticamente con una validez de 365 días.

### Generación manual (opcional)

Si prefieres generar los certificados manualmente antes de construir las imágenes, puedes hacerlo:

**Para Apache** (en `apache/certs/`):

Los certificados para Apache se pueden generar manualmente con OpenSSL:

Los certificados para Apache se generan con OpenSSL y se almacenan en `apache/certs/`:

```bash
cd apache/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout server.key \
  -out server.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=Stack02/OU=IT/CN=localhost"
```

Esto genera:
- `server.key`: Clave privada
- `server.crt`: Certificado público

**Para WildFly** (en `wildfly/certs/`):

El keystore para WildFly se puede generar manualmente con `keytool` (incluido en el JDK):

```bash
cd wildfly/certs
keytool -genkeypair -alias wildfly -keyalg RSA -keysize 2048 \
  -validity 365 -keystore wildfly.keystore \
  -storepass password -keypass password \
  -dname "CN=localhost, OU=IT, O=Stack02, L=Madrid, ST=Madrid, C=ES"
```

Esto genera:
- `wildfly.keystore`: Keystore JKS con el certificado y clave privada
- Contraseña del keystore: `password`

Si generas los certificados manualmente, los contenedores los detectarán y usarán en lugar de generar nuevos.

**Nota importante**: Los certificados autofirmados son válidos para desarrollo local. El navegador mostrará advertencias de seguridad que puedes aceptar. Para producción, debes usar certificados firmados por una CA reconocida.

### Usar certificados propios en producción

Para usar tus propios certificados en producción:

1. **Apache**: Coloca tus certificados en el volumen `apache_certs` o móntalo desde el host
2. **WildFly**: Coloca tu keystore en el volumen `wildfly_data` antes del primer arranque
3. Ajusta las configuraciones en `httpd.conf` y el Dockerfile de WildFly según sea necesario

## Notas

- El `docker-compose.yml` de este stack no usa la clave `version`.
- WildFly se construye desde `stack02/wildfly/Dockerfile`. Ajusta el Dockerfile si necesitas módulos adicionales.
- Elasticsearch se configura en modo `single-node` mediante `discovery.type=single-node` .
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

### Conexión a Active Directory (LDAP + StartTLS)
Ejemplo (Apache Directory Studio):
- Host: `localhost`
- Puerto: `389`
- Security/Encryption: `StartTLS`
- Bind DN o UPN: `administrator@stack02.local`
- Password: `Admin_Password_2025!`
- Acepta el certificado autofirmado del contenedor (o marca “Trust all” en entornos de dev)

### Crear usuarios adicionales en Active Directory

El usuario `ijgomez` se crea automáticamente al levantar el contenedor. Para crear usuarios extra en AD ejecuta (ajusta datos según tu caso):

```bash
cd stack02
docker exec -i stack02_ad samba-tool user create nuevo_usuario \
	--password='Password.1234' \
	--given-name='Nombre' \
	--surname='Apellido' \
	--mail-address='nuevo_usuario@stack02.local'
```

Luego conéctate con las credenciales definidas usando StartTLS en Apache Directory Studio.

### Provisionar usuarios y grupos vía CSV

- Usuarios: `stack02/samba-ad/users.csv` (cabecera `userId;password;displayName;name;mail;memberOf`).
- Grupos: `stack02/samba-ad/groups.csv` (cabecera `name;ou;description`).
- Si necesitas usar otras rutas dentro del contenedor, puedes sobrescribir con las variables `USERS_CSV_FILE` y `GROUPS_CSV_FILE`.

