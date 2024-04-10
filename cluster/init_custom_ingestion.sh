#!/bin/bash

# This JWT Token is signed by the fixed key pair provided with the OpenMetaData demo and thus can be used even if not configured in the web UI.
# If this stops working, i.e. if the key pair has been changed, grab an updated key from the "openmetadata_ingestion" container:
# docker compose exec ingestion bash -c 'grep jwtToken /opt/airflow/dags/*'
# Use any of the jwtTokens
JWT_TOKEN="eyJraWQiOiJHYjM4OWEtOWY3Ni1nZGpzLWE5MmotMDI0MmJrOTQzNTYiLCJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJvcGVuLW1ldGFkYXRhLm9yZyIsInN1YiI6ImluZ2VzdGlvbi1ib3QiLCJlbWFpbCI6ImluZ2VzdGlvbi1ib3RAb3Blbm1ldGFkYXRhLm9yZyIsImlzQm90Ijp0cnVlLCJ0b2tlblR5cGUiOiJCT1QiLCJpYXQiOjE3MTI0MTM1NzIsImV4cCI6bnVsbH0.lc__HkQtXDfimQtONbAMwyljK9Sjlw7z0G6bz8GoT2-t5dq1ptN9NFnodRgA-WAqNgc4-umMKQpFYErBIwjNY-dCvB6wE6GdpR7ceAoqKySQHNvx4DPIB6jAHK0dVwtSIArTA_boYjXxUnv2wpTVr8b5kfNmoLiMI3tPb7tqgXyUemQDnNMCXKepAkPTb10fpNDCbH8n5oTwieqB1Wl9PLNxJhRXct-GuWtaWibtxTtcp7mBNEkTRIef4YJmqZyqE2EJAcbKo2KJahEonKEcQD8DHf1GtCaRLNARnbrdo5t5rIFxipiP4-_iLBtKB1KIZy7fjvSPXhrIljzprOSBvQ"

echo "Creating topics"
kafka-topics --bootstrap-server broker:9092 --create --topic topic-1 --partitions 1
kafka-topics --bootstrap-server broker:9092 --create --topic topic-2 --partitions 1
kafka-topics --bootstrap-server broker:9092 --create --topic topic-3 --partitions 1

echo "Setting compatibility modes"
curl -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "FORWARD_TRANSITIVE"}' \
  http://schema-registry:8081/config/topic-1-value
#
curl -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "FORWARD_TRANSITIVE"}' \
  http://schema-registry:8081/config/topic-2-value
#
curl -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"compatibility": "FORWARD_TRANSITIVE"}' \
  http://schema-registry:8081/config/topic-3-value

echo "Creating schemas"
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema": "{\"namespace\": \"models.avro\", \"type\": \"record\", \"name\": \"SimpleValue\", \"fields\": [ {\"name\": \"theName\", \"type\": \"string\"}, {\"name\": \"theValue\", \"type\": \"string\"}]}"}' \
  http://schema-registry:8081/subjects/topic-1-value/versions
#
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema": "{\"namespace\": \"models.avro\", \"type\": \"record\", \"name\": \"SimpleValue\", \"fields\": [ {\"name\": \"theName\", \"type\": \"string\"}, {\"name\": \"theValue\", \"type\": \"string\"}]}"}' \
  http://schema-registry:8081/subjects/topic-2-value/versions
#
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  --data '{"schema": "{\"namespace\": \"models.avro\", \"type\": \"record\", \"name\": \"SimpleValue\", \"fields\": [ {\"name\": \"theName\", \"type\": \"string\"}, {\"name\": \"theValue\", \"type\": \"string\"}]}"}' \
  http://schema-registry:8081/subjects/topic-3-value/versions

echo "Creating OpenMetaData service for kafka..."
export SERVICE_ID=$(curl --request POST --header "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" --data \
'{"name":"kafka",
  "serviceType":"Kafka",
  "description":"",
  "connection":{"config":
    {"type":"Kafka",
      "bootstrapServers":"broker:9092",
      "schemaRegistryURL":"http://schema-registry:8081",
      "saslMechanism":"PLAIN",
      "supportsMetadataExtraction":true
    }}
}' \
http://openmetadata_server:8585/api/v1/services/messagingServices | grep -oP '(?<="id":")[^"]+')
if [ -n ${SERVICE_ID} ]; then
    echo "Created service Kafka with ID ${SERVICE_ID}"
    echo "Creating ingestion pipeline for kafka..."
    export INGESTION_ID=$(curl --request POST --header "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" --data \
        "{\"name\":\"kafka_metadata_8rmIGMAX\",
          \"displayName\":\"kafka_metadata_8rmIGMAX\",
          \"pipelineType\":\"metadata\",
          \"sourceConfig\":
          {\"config\":
            {\"type\":\"MessagingMetadata\",
              \"markDeletedTopics\":true,
              \"generateSampleData\":true,
              \"topicFilterPattern\":
               {
                 \"excludes\":[\"^_.*\"],
                 \"includes\":[]
               }
            }
          },
          \"airflowConfig\":
          {\"pausePipeline\":false,
           \"concurrency\":1,
           \"startDate\":1712275200000,
           \"pipelineTimezone\":\"UTC\",
           \"retries\":3,
           \"retryDelay\":300,
           \"pipelineCatchup\":false,
           \"scheduleInterval\":\"*/5 * * * *\",
           \"maxActiveRuns\":1,
           \"workflowDefaultView\":\"tree\",
           \"workflowDefaultViewOrientation\":\"LR\"
          },
          \"service\":
          {
           \"id\":\"${SERVICE_ID}\",\"type\":
           \"messagingService\",
           \"name\":\"kafka\",
           \"fullyQualifiedName\":\"kafka\",
           \"description\":\"\",
           \"deleted\":false,
           \"href\":\"http://localhost:8585/api/v1/services/messagingServices/${SERVICE_ID}\"
          } 
        }" \
        http://openmetadata_server:8585/api/v1/services/ingestionPipelines | grep -oP '(?<=^{"id":")[^"]+')
        #
        echo "Deploying ingestion for Kafka service..."
        curl --request POST --header "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" http://openmetadata_server:8585/api/v1/services/ingestionPipelines/deploy/${INGESTION_ID}
fi

echo "Done."
