FROM nowsci/samba-domain

ARG AD_DOMAIN
ARG AD_DOMAINPASS

# Copiar script de creación de usuarios
COPY create-users.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create-users.sh

# Ejecutar script en background al iniciar
# RUN echo '#!/bin/bash\n/usr/local/bin/create-users.sh &\nrun' >> /entrypoint.sh && chmod +x /entrypoint.sh
