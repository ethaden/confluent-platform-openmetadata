/*
 * This file was generated by the Gradle 'init' task.
 */

plugins {
    id("io.confluent.csta.examples.transactions.java-application-conventions")
    id("com.ryandens.javaagent-application") version "0.4.2"
}

dependencies {
    javaagent("io.opentelemetry.javaagent:opentelemetry-javaagent:2.1.0")
}

application {
    // Define the main class for the application.
    mainClass.set("io.confluent.csta.examples.transactions.consumer.transactional.TransactionalConsumer")
    applicationDefaultJvmArgs = listOf("-Dotel.javaagent.debug=true", "-Dotel.metrics.exporter=none", "-Dotel.traces.exporter=jaeger", "-Dotel.service.name=kafka", "-Dotel.instrumentation.messaging.experimental.receive-telemetry.enabled=true")
}

tasks.run<JavaExec> {
    args(listOf("../consumer-transactional.properties"))
}
