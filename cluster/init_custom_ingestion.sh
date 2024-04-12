#!/bin/bash

# JWTs have limited validity. We need to grab a newly created one

if [ -z ${JWT_TOKEN} ]; then
  JWT_TOKEN=$(grep -oP '(?<=jwtToken: \")[^"]+' /opt/airflow/dags/airflow_docker_operator.py)
fi

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
           \"description\":\"Demo Kafka Message Service\",
           \"deleted\":false,
           \"href\":\"http://localhost:8585/api/v1/services/messagingServices/${SERVICE_ID}\"
          } 
        }" \
        http://openmetadata_server:8585/api/v1/services/ingestionPipelines | grep -oP '(?<=^{"id":")[^"]+')
        #
        echo "Deploying ingestion for Kafka service..."
        curl --request POST --header "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" http://openmetadata_server:8585/api/v1/services/ingestionPipelines/deploy/${INGESTION_ID}
fi
echo "Setting up MariaDB service"
export SERVICE_ID=$(curl --request POST --header "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" --data \
"{\"name\":\"mariadb\",
  \"serviceType\":\"MariaDB\",
  \"description\":\"\",
  \"connection\":{\"config\":
    {\"type\":\"MariaDB\",
      \"scheme\":\"mysql+pymysql\",
      \"username\":\"${MARIADB_OPENMETADATA_USER}\",
      \"password\":\"${MARIADB_OPENMETADATA_PASSWORD}\",
      \"hostPort\":\"mariadb:3306\",
      \"databaseName\":\"demo\",
      \"supportsMetadataExtraction\":true,
      \"supportsDBTExtraction\":true,
      \"supportsProfiler\":true,
      \"supportsQueryComment\":true
    }}
}" \
http://openmetadata_server:8585/api/v1/services/databaseServices | grep -oP '(?<="id":")[^"]+')
if [ -n ${SERVICE_ID} ]; then
    echo "Created service MariaDB with ID ${SERVICE_ID}"
    echo "Creating ingestion pipeline for MariaDB..."
    export INGESTION_ID=$(curl --request POST --header "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" --data \
        "{\"name\":\"mariadb_metadata_wUMTfesN\",
          \"displayName\":\"mariadb_metadata_wUMTfesN\",
          \"pipelineType\":\"metadata\",
          \"sourceConfig\":
          {\"config\":
            {\"type\":\"DatabaseMetadata\",
              \"includeTags\":true,
              \"includeViews\":true,
              \"includeTables\":true,
              \"markDeletedTables\":true,
              \"tableFilterPattern\":{
                \"excludes\":[],
                \"includes\":[]
              },
              \"useFqnForFiltering\":false,
              \"schemaFilterPattern\":{
                \"excludes\":[],
                \"includes\":[]
              },
              \"markAllDeletedTables\":false,
              \"databaseFilterPattern\":{
                \"excludes\":[],
                \"includes\":[]
              },
              \"viewParsingTimeoutLimit\":300
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
           \"id\":\"${SERVICE_ID}\",
           \"type\":\"databaseService\",
           \"name\":\"mariadb\",
           \"fullyQualifiedName\":\"mariadb\",
           \"description\":\"\",
           \"deleted\":false,
           \"href\":\"http://localhost:8585/api/v1/services/databaseServices/${SERVICE_ID}\"
          }
        }" \
        http://openmetadata_server:8585/api/v1/services/ingestionPipelines | grep -oP '(?<=^{"id":")[^"]+')
        #
        echo "Deploying ingestion for Mariadb service..."
        curl --request POST --header "Content-Type: application/json" -H "Authorization: Bearer ${JWT_TOKEN}" http://openmetadata_server:8585/api/v1/services/ingestionPipelines/deploy/${INGESTION_ID}
fi

echo "Done."
