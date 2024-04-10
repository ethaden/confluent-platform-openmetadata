ARG CP_TAG
FROM confluentinc/cp-server-connect-base:$CP_TAG

RUN   confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.2 \
   && confluent-hub install --no-prompt debezium/debezium-connector-mysql:2.4.2 \
   && confluent-hub install --no-prompt debezium/debezium-connector-postgresql:2.5.3
