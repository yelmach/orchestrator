FROM alpine:3.23

RUN apk add --no-cache postgresql postgresql-client su-exec

COPY entrypoint.sh .

RUN chmod +x /entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/entrypoint.sh"]