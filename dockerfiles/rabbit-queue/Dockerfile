FROM alpine:3.23

RUN apk add --no-cache rabbitmq-server

RUN mkdir -p /etc/rabbitmq /var/lib/rabbitmq /var/log/rabbitmq && \
    chown -R rabbitmq:rabbitmq /etc/rabbitmq /var/lib/rabbitmq /var/log/rabbitmq

EXPOSE 5672

USER rabbitmq

ENTRYPOINT ["rabbitmq-server"]