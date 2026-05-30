allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    // Note: do not force a global Java/Kotlin jvmTarget here. Each plugin sets
    // its own (internally consistent) target; overriding only Kotlin caused
    // "Inconsistent JVM-target" failures (maplibre 21, pusher 11, app 17).
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
