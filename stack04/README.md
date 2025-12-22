# Stack04

Stack de ejemplo que contiene:
- `apache` (Apache 2.4, reverse proxy a Tomcat 8.5/Java 8)
- `tomcat` (Tomcat 8.5, JDK 8)
- `elasticsearch` (Elasticsearch 7.6.2)
- `samba-ad` (Active Directory basado en Samba)
- `mysql` (MySQL 8.4)

Ver la documentación general del repositorio en `../README.md`.

## Requisitos
- Docker y Docker Compose (v1 o v2).

## Levantar el stack
Desde el directorio `stack04` ejecuta:

```bash
docker compose up -d --build
# o
./start.sh
```

## Accesos
- Apache: http://localhost:8080 (proxy a Tomcat)
- Tomcat: http://localhost:8081
- Elasticsearch: http://localhost:9200
- Active Directory (Samba AD): ldap://localhost:389 (LDAPS 636)
- MySQL: host `localhost`, puerto `3306` (credenciales abajo)

Credenciales MySQL por defecto:
- `MYSQL_ROOT_PASSWORD=Root_Password_2025!`
- `MYSQL_DATABASE=appdb`
- `MYSQL_USER=appuser`
- `MYSQL_PASSWORD=AppUser_Password_2025!`

## Servicios definidos en el stack

- `apache`:
  - Imagen: `httpd:2.4` (`stack04/apache/httpd.conf`).
  - Función: reverse-proxy hacia `tomcat:8080`.
  - Puertos: `8080` expuesto en el host.

- `tomcat`:
  - Build: `./tomcat` (base `tomcat:8.5-jdk8-temurin`).
  - Puertos: `8081` expuesto en el host.

- `elasticsearch`:
  - Imagen: `docker.elastic.co/elasticsearch/elasticsearch:7.6.2`.
  - Config: `discovery.type=single-node`, `ES_JAVA_OPTS=-Xms512m -Xmx512m`.
  - Puertos: `9200` expuesto en el host.
  - Volumen: `es_data` para datos.

- `samba-ad`:
  - Imagen: `nowsci/samba-domain:latest`.
  - Dominio: `stack04.local` (`DOMAINPASS` define la contraseña admin).
  - Puertos: `389/636` expuestos en el host.
  - Volumen: `samba_data`.

- `mysql`:
  - Imagen: `mysql:8.4`.
  - Puertos: `3306` expuesto en el host.
  - Volumen: `mysql_data` para datos.
  - Plugin de auth: `mysql_native_password` (por comando de arranque).

## Scripts
- `start.sh`: levanta y (si aplica) reconstruye servicios.
- `stop.sh`: baja los contenedores (`docker compose down`).
