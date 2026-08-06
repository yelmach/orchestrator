FROM alpine:3.23

RUN apk add --no-cache postgresql postgresql-client su-exec

RUN mkdir -p /run/postgresql /var/lib/postgresql/data && \
    chown -R postgres:postgres /run/postgresql /var/lib/postgresql/data

COPY entrypoint.sh .
RUN chmod +x /entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/entrypoint.sh"]