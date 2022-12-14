FROM postgres:15.1-alpine

ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev libintl 
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl

RUN apk add --no-cache \
    $MUSL_LOCALE_DEPS \
    && wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
      && cd musl-locales-master \
      && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
      && cd .. && rm -r musl-locales-master

ENV LANG es_ES.UTF-8 
ENV LANGUAGE es_ES:es
ENV LC_ALL es_ES.UTF-8

COPY --chmod=0755 ./config/01-create-users.sh /docker-entrypoint-initdb.d/
COPY --chmod=0755 ./config/02-create-tablespaces.sh /docker-entrypoint-initdb.d/
COPY --chmod=0755 ./config/03-create-databases.sh /docker-entrypoint-initdb.d/
COPY --chmod=0755 ./config/04-create-schemas.sh /docker-entrypoint-initdb.d/
COPY --chmod=0755 ./config/05-create-grants.sh /docker-entrypoint-initdb.d/
