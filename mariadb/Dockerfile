FROM mariadb:10.10.1

RUN ehck "USE mysql;" > docker-entrypoint-initdb.d/timezones.sql && mysql_tzinfo_to_sql /usr/share/zoneinfo >> docker-entrypoint-initdb.d/timezones.sql

COPY ./my.cnf /etc/mysql/conf.d/my.cnf