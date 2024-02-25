/*
 * This file was generated by the Gradle 'init' task.
 */
import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar

plugins {
    id("io.confluent.csta.examples.transactions.java-application-conventions")
    id("com.github.johnrengelman.shadow")
}

val agent = configurations.create("agent")

dependencies {
    agent("io.opentelemetry.javaagent:opentelemetry-javaagent:2.1.0")
}

val copyAgent = tasks.register<Copy>("copyAgent") {
    from(agent.singleFile)
    into(layout.buildDirectory.dir("agent"))
    rename("opentelemetry-javaagent-.*\\.jar", "opentelemetry-javaagent.jar")
}

tasks.named("build") { 
    //finalizedBy("copyAgent")
    dependsOn(tasks.withType<Copy>())
}

application {
    // Define the main class for the application.
    mainClass.set("io.confluent.csta.examples.transactions.producer.transactional.TransactionalProducer")
    applicationDefaultJvmArgs = listOf(
        "-javaagent:build/agent/opentelemetry-javaagent.jar",
        "-Dotel.javaagent.debug=false", 
        "-Dotel.metrics.exporter=none", 
        "-Dotel.traces.exporter=otlp", 
        "-Dotel.service.name=kafka")
    println(sourceSets.main.get().runtimeClasspath)
}

tasks.run<JavaExec> {
    args(listOf("../producer-transactional.properties"))
}

tasks.withType<ShadowJar>() {
    manifest {
        attributes["Main-Class"] = "io.confluent.csta.examples.transactions.producer.transactional.TransactionalProducer"
    }
}
