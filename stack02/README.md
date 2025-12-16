## Stack02

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

## Notas

- Elasticsearch se configura en modo `single-node` mediante `discovery.type=single-node` y se expone en los puertos 9200/9300 en el host.
- WildFly se construye desde `stack02/wildfly/Dockerfile`. Ajusta el Dockerfile si necesitas módulos adicionales.
- Los datos de Elasticsearch se almacenan en el volumen `es_data`.

Si quieres, puedo:
- añadir un `Dockerfile` más avanzado para WildFly con usuario no-root y entrypoint personalizado (similar al de `stack01`),
- añadir scripts `start.sh` / `stop.sh` para este stack, o
- levantar el stack ahora y comprobar que los servicios arrancan correctamente.
