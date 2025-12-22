# Stack05

Stack de ejemplo que contiene:
- `nginx` (reverse proxy a Tomcat 9/Java 8)
- `tomcat` (Tomcat 9, JDK 8)
- `samba-ad` (Active Directory basado en Samba)
- `ftp` (servidor FTP `fauria/vsftpd`)
- `sql-edge` (Azure SQL Edge)

Ver la documentación general del repositorio en `../README.md`.

## Requisitos
- Docker y Docker Compose (v1 o v2).

## Levantar el stack
Desde el directorio `stack05` ejecuta:

```bash
docker compose up -d --build
# o
./start.sh
```

## Accesos
- Nginx: http://localhost:8080 (proxy a Tomcat)
- Tomcat: http://localhost:8081
- Active Directory (Samba AD): ldap://localhost:389 (LDAPS 636)
- FTP: host `localhost`, puerto `21`, pasivos `21100-21110`
- SQL Edge: host `localhost`, puerto `1433`

Credenciales FTP por defecto:
- `FTP_USER=ftpuser`
- `FTP_PASS=ftp_password_2025!`

## Servicios definidos en el stack

- `nginx`:
  - Imagen: `nginx:1.25` (`stack05/nginx/nginx.conf`).
  - Función: reverse-proxy hacia `tomcat:8080`.
  - Puertos: `8080` expuesto en el host.

- `tomcat`:
  - Build: `./tomcat` (base `tomcat:9.0-jdk8-temurin`).
  - Puertos: `8081` expuesto en el host.

- `samba-ad`:
  - Imagen: `nowsci/samba-domain:latest`.
  - Dominio: `stack05.local` (`DOMAINPASS` define la contraseña admin).
  - Puertos: `389/636` expuestos en el host.
  - Volumen: `samba_data`.

- `ftp`:
  - Imagen: `fauria/vsftpd`.
  - Puertos: `21` y `21100-21110` expuestos en el host.
  - Volumen: `ftp_data` para datos.

- `sql-edge`:
  - Imagen: `mcr.microsoft.com/azure-sql-edge:latest`.
  - Puertos: `1433` expuesto en el host.
  - Volumen: `sql_edge_data` para datos.
  - Credenciales por defecto: `SA` / `SqlEdge_Password_2025!` (`MSSQL_SA_PASSWORD`).

## Scripts
- `start.sh`: levanta y (si aplica) reconstruye servicios.
- `stop.sh`: baja los contenedores (`docker compose down`).
