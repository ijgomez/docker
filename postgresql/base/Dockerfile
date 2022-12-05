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


# COPY init.sql /docker-entrypoint-initdb.d/

# COPY init-user-db.sh /docker-entrypoint-initdb.d/

# COPY init-user-template-db.sh /docker-entrypoint-initdb.d/
# COPY init-user-support-db.sh /docker-entrypoint-initdb.d/
