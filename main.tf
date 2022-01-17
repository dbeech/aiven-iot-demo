variable "aiven_api_token" {}
variable "project_name" {}
variable "kafka_version" {}
variable "service_cloud" {}
variable "service_name_prefix" {}
variable "service_plan_cassandra" {}
variable "service_plan_flink" {}
variable "service_plan_influxdb" {}
variable "service_plan_kafka" {}
variable "service_plan_kafka_connect" {}
variable "service_plan_kafka_mm2" {}
variable "service_plan_kafka_replica" {}
variable "service_plan_elastic" {}
variable "service_plan_grafana" {}
variable "service_plan_m3db" {}
variable "service_plan_mysql" {}
variable "service_plan_opensearch" {}
variable "service_plan_pg" {}
variable "service_plan_redis" {}

terraform {
  required_providers {
    aiven = {
      source = "aiven/aiven"
      version = "2.4.0"
    }
  }
}

provider "aiven" {
  api_token = var.aiven_api_token
}

resource "aiven_kafka" "bbp-demo-kafka" {
  project                 = var.project_name
  cloud_name              = var.service_cloud
  plan                    = var.service_plan_kafka
#  project_vpc_id          = "${var.project_name}/${var.project_vpc_id}"
  service_name            = "${var.service_name_prefix}-kafka"
  default_acl             = false
  termination_protection  = false
  kafka_user_config {
    schema_registry = true
    kafka_rest = true
    kafka_connect = true
    kafka_version = var.kafka_version
    ip_filter = ["0.0.0.0/0"]
    kafka {
      auto_create_topics_enable = true
    }  
    public_access {
      kafka = false
      kafka_rest = false
      kafka_connect = true
      schema_registry = false
    }
  }
}

resource "aiven_kafka_connector" "bbp-demo-kafka-connector-influx" {
  project        = var.project_name
  service_name   = aiven_kafka.bbp-demo-kafka.service_name
  connector_name = "bbp-demo-kafka-connector-influx"
  config = {
    "name"                           = "bbp-demo-kafka-connector-influx"
    "topics"                         = aiven_kafka_topic.bbp-demo-kafka-topic-sensor-readings-to-influx.topic_name
    "connector.class"                = "com.datamountaineer.streamreactor.connect.influx.InfluxSinkConnector"
    "connect.influx.url"             = "https://${aiven_influxdb.bbp-demo-timeseries-influx.service_host}:${aiven_influxdb.bbp-demo-timeseries-influx.service_port}",
    "connect.influx.db"              = "defaultdb",
    "connect.influx.username"        = aiven_influxdb.bbp-demo-timeseries-influx.service_username
    "connect.influx.password"        = aiven_influxdb.bbp-demo-timeseries-influx.service_password
    "connect.influx.kcql"            = "INSERT INTO sensor_reading SELECT * FROM ${aiven_kafka_topic.bbp-demo-kafka-topic-sensor-readings-to-influx.topic_name} WITHTIMESTAMP sys_time() WITHTAG (sensor_id)"
    # ref: https://docs.lenses.io/4.3/integrations/connectors/stream-reactor/sinks/payloads/
    "key.converter"                  = "org.apache.kafka.connect.json.JsonConverter"
    "key.converter.schemas.enable"   = "false"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter.schemas.enable" = "false"
  }
}

resource "aiven_kafka_connector" "bbp-demo-kafka-connector-m3" {
  project        = var.project_name
  service_name   = aiven_kafka.bbp-demo-kafka.service_name
  connector_name = "bbp-demo-kafka-connector-m3"
  config = {
    "name"                           = "bbp-demo-kafka-connector-m3"
    "topics"                         = aiven_kafka_topic.bbp-demo-kafka-topic-sensor-readings-to-m3.topic_name
    "connector.class"                = "com.datamountaineer.streamreactor.connect.influx.InfluxSinkConnector"
    "connect.influx.url"             = "https://${aiven_m3db.bbp-demo-timeseries-m3.service_host}:${aiven_m3db.bbp-demo-timeseries-m3.service_port}/api/v1/influxdb/",
    "connect.influx.db"              = "defaultdb",
    "connect.influx.username"        = aiven_m3db.bbp-demo-timeseries-m3.service_username
    "connect.influx.password"        = aiven_m3db.bbp-demo-timeseries-m3.service_password
    "connect.influx.kcql"            = "INSERT INTO sensor_reading SELECT * FROM ${aiven_kafka_topic.bbp-demo-kafka-topic-sensor-readings-to-m3.topic_name} WITHTIMESTAMP sys_time() WITHTAG (sensor_id)"
    "connect.influx.error.policy"    = "THROW",
    "connect.progress.enabled"       = "true",
    # ref: https://docs.lenses.io/4.3/integrations/connectors/stream-reactor/sinks/payloads/
    "key.converter"                  = "org.apache.kafka.connect.json.JsonConverter"
    "key.converter.schemas.enable"   = "false"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter.schemas.enable" = "false"
  }
}

resource "aiven_m3db" "bbp-demo-timeseries-m3" {
  project                 = var.project_name 
  cloud_name              = var.service_cloud
  plan                    = var.service_plan_m3db
#  project_vpc_id          = "${var.project_name}/${var.project_vpc_id}"
  service_name            = "${var.service_name_prefix}-timeseries-m3"
  m3db_user_config {
    ip_filter = ["0.0.0.0/0"]
    namespaces {
      name = "default"
      type = "unaggregated"
      options {
        retention_options {
          blocksize_duration        = "2h"
          retention_period_duration = "48h"
        }
      }
    }
  }
}

resource "aiven_influxdb" "bbp-demo-timeseries-influx" {
  project                 = var.project_name 
  cloud_name              = var.service_cloud
  plan                    = var.service_plan_influxdb
  service_name            = "${var.service_name_prefix}-timeseries-influxdb"
  influxdb_user_config {
    ip_filter = ["0.0.0.0/0"]
    public_access {
      influxdb = false
    }
  }
}

resource "aiven_grafana" "bbp-demo-dashboard" {
  project                = var.project_name
  cloud_name             = var.service_cloud
  plan                   = var.service_plan_grafana
#  project_vpc_id          = "${var.project_name}/${var.project_vpc_id}"
  service_name           = "${var.service_name_prefix}-dashboard"
  grafana_user_config {
    ip_filter = ["0.0.0.0/0"]
    public_access {
      grafana = true
    }
  }
}

# Metrics integration: Kafka -> M3
# resource "aiven_service_integration" "dbeech-demo-kafka-integration-metrics" {
#   project                  = var.project_name
#   integration_type         = "metrics"
#   source_service_name      = aiven_kafka.bbp-demo-kafka.service_name
#   destination_service_name = aiven_m3db.bbp-demo-timeseries.service_name
# }

# Dashboard integration: InfluxDB -> Grafana
resource "aiven_service_integration" "bbp-demo-integration-dashboard-influx" {
  project                  = var.project_name
  integration_type         = "dashboard"
  source_service_name      = aiven_grafana.bbp-demo-dashboard.service_name
  destination_service_name = aiven_influxdb.bbp-demo-timeseries-influx.service_name
}

# Dashboard integration: M3 -> Grafana
resource "aiven_service_integration" "bbp-demo-integration-dashboard-m3" {
  project                  = var.project_name
  integration_type         = "dashboard"
  source_service_name      = aiven_grafana.bbp-demo-dashboard.service_name
  destination_service_name = aiven_m3db.bbp-demo-timeseries-m3.service_name
}

resource "aiven_kafka_topic" "bbp-demo-kafka-topic-sensor-readings-to-influx" {
  project                  = var.project_name
  service_name             = aiven_kafka.bbp-demo-kafka.service_name
  topic_name               = "sensor-readings-to-influx"
  partitions               = 3
  replication              = 3
  config {
    retention_ms = 604800000
  }
}

resource "aiven_kafka_topic" "bbp-demo-kafka-topic-sensor-readings-to-m3" {
  project                  = var.project_name
  service_name             = aiven_kafka.bbp-demo-kafka.service_name
  topic_name               = "sensor-readings-to-m3"
  partitions               = 3
  replication              = 3
  config {
    retention_ms = 604800000
  }
}