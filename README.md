# Docker
Repository with several Docker stacks and examples.

**Stack01**
- **Descripción**: Stack compuesto por `postgres`, `wildfly` y `apache` (Apache actúa como reverse proxy hacia WildFly).
- **Ubicación**: `stack01/`.
- **Servicios**:
	- **Postgres**: imagen `postgres:14` — puerto `5432:5432` — volumen `postgres_data:/var/lib/postgresql/data` — variables: `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`.
	- **WildFly**: construye desde `./stack01/wildfly` — puertos `8080:8080` (app) y `9990:9990` (management) — variables: `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`.
	- **Apache**: imagen `httpd:2.4` — puerto `80:80` — monta `./stack01/apache/httpd.conf` que proxifica hacia `wildfly:8080`.
- **Volúmenes**: `postgres_data` persiste la base de datos PostgreSQL.

**Cómo usar**
- **Levantar el stack**: desde la raíz o desde `stack01/` ejecutar:
	- `./stack01/start.sh`
	- o `docker compose -f stack01/docker-compose.yml up -d --build`
- **Parar el stack**:
	- `./stack01/stop.sh`
	- o `docker compose -f stack01/docker-compose.yml down`
- **Reiniciar sólo Apache** (útil después de cambiar `httpd.conf`):
	- `cd stack01 && docker compose restart apache`

**Archivos importantes**
- `stack01/docker-compose.yml`: definición de servicios.
- `stack01/apache/httpd.conf`: configuración del proxy hacia WildFly.
- `stack01/start.sh`, `stack01/stop.sh`: wrappers convenientes que detectan `docker compose` o `docker-compose`.

**Acceso y puertos**
- Apache (frontend): `http://localhost:80` → proxifica a WildFly.
- WildFly (app): `http://localhost:8080`.
- WildFly (management): `http://localhost:9990`.
- Postgres: puerto `5432` (localmente `localhost:5432`).

**Logs y debugging**
- Ver logs de un servicio: `docker logs -f <container>` (ej.: `docker logs -f apache`).
- Si Apache no sirve contenido, revisar `stack01/apache/httpd.conf` y confirmar que `wildfly` está arriba.
- Si hay conflictos de puertos, comprobar procesos locales que ocupen `80`, `8080`, `5432`.

**Notas y recomendaciones**
- Asegúrate de tener Docker y Docker Compose (v1 o v2) instalados; los scripts detectan ambos (`docker-compose` o `docker compose`).
- Para desarrollo de la aplicación en WildFly, reconstruye sólo el servicio: `docker compose -f stack01/docker-compose.yml up -d --build wildfly`.
- Respaldos: realiza dumps de la base de datos PostgreSQL antes de eliminar el volumen `postgres_data`.

Si quieres, puedo crear además un `stack01/README.md` independiente o generar instrucciones de contribución y un ejemplo para desplegar datos iniciales.