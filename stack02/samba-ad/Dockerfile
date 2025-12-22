FROM nowsci/samba-domain

ARG DOMAIN
ARG DOMAINPASS

# Copiar script de creación de usuarios
COPY create-users.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create-users.sh

# Inyectar la ejecución del script antes de appStart en /init.sh
RUN python3 - <<'PY'
from pathlib import Path

path = Path('/init.sh')
text = path.read_text()

hook = "# Ejecutar script de creación de usuarios en background\n/usr/local/bin/create-users.sh &\n"
needle = "appStart ${FIRSTRUN}\n"

# Evita duplicados del hook
text = text.replace(hook, '')

if needle not in text:
	raise SystemExit('No se encontró el punto de inserción en /init.sh')

text = text.replace(needle, hook + needle, 1)
path.write_text(text)
PY
