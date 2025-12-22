# Stack03

Stack de ejemplo que contiene:
- `apache` (Apache 2.4, reverse proxy a Tomcat 8.5/Java 8)
- `tomcat` (Tomcat 8.5, JDK 8)
- `elasticsearch` (Elasticsearch 7.6.2)
- `samba-ad` (Active Directory basado en Samba)
- `oracle` (Oracle Database Free)

Ver la documentación general del repositorio en `../README.md`.

## Requisitos
- Docker y Docker Compose (v1 o v2).

## Levantar el stack
Desde el directorio `stack03` ejecuta:

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
- Oracle DB: host `localhost`, puerto `1521` (EM Express `5500`)

## Servicios definidos en el stack

- `apache`:
  - Imagen: `httpd:2.4` (`stack03/apache/httpd.conf`).
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
  - Imagen: `stack02/samba-domain:latest` (nowsci/samba-domain base).
  - Dominio: `stack03.local` (credencial admin por variable `DOMAINPASS`).
  - Puertos: `389/636` expuestos en el host.
  - Volumen: `samba_data`.

- `oracle`:
  - Imagen: `gvenzl/oracle-free:latest`.
  - Puertos: `1521` (SQL*Net) y `5500` (EM Express) expuestos en el host.
  - Volumen: `oracle_data` para datos.
  - Credenciales por defecto: `ORACLE_PASSWORD=Oracle_Password_2025!`, usuario app: `appuser` / `AppUser_Password_2025!`.

## Scripts
- `start.sh`: levanta y (si aplica) reconstruye servicios.
- `stop.sh`: baja los contenedores (`docker compose down`).
