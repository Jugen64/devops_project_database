FROM postgres:15.6-alpine

ENV POSTGRES_DB=ecommerce
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=admin

COPY db/init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
