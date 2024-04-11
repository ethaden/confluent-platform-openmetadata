#!/bin/bash

curl -X "POST" "http://connect:8083/connectors" \
     -H "Content-Type: application/json" \
     -d "{
  \"name\": \"mariadb-source\",
  \"config\": {
    \"connector.class\": \"io.debezium.connector.mysql.MySqlConnector\",
    \"tasks.max\": \"1\",
    \"database.protocol\": \"jdbc:mysql\",
    \"database.hostname\": \"mariadb\",
    \"database.user\": \"${MARIADB_CONNECT_USER}\",
    \"database.password\": \"${MARIADB_CONNECT_PASSWORD}\",
    \"topic.prefix\": \"mariadb\",
    \"database.server.id\": 1,
    \"database.include.list\": \"demo\",
    \"schema.name.adjustment.mode\": \"avro\",
    \"field.name.adjustment.mode\": \"avro\",
    \"schema.history.internal.kafka.bootstrap.servers\": \"broker:9092\", 
    \"schema.history.internal.kafka.topic\": \"schemahistory.mariadb\"
  }
}"
    # "connector.adapter": "mariadb",
    # "database.jdbc.driver": "org.mariadb.jdbc.Driver",
    # "connector.adapter": "mariadb",
    # "database.protocol": "jdbc:mariadb",
    # "database.jdbc.driver": "org.mariadb.jdbc.Driver",
