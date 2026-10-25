// Platform-neutral logic: payload encoding, rounding, sending on change, aggregation, sensor selection,
// queue batching, and journal notes. Plain Kotlin without Android, so its tests run on the JVM.
plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(libs.kotlinx.serialization.json)
    testImplementation(kotlin("test"))
    testRuntimeOnly(libs.junit.platform.launcher)
}

val vectors = rootProject.layout.projectDirectory.dir("../docs/spec/vectors")

tasks.test {
    useJUnitPlatform()
    inputs.dir(vectors).withPropertyName("vectors")
    systemProperty("vectorsDir", vectors.asFile.absolutePath)
}
