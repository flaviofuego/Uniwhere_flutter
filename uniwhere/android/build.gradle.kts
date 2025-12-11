buildscript {
    extra.apply {
        set("kotlin_version", "2.1.0")
    }
}

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
}
subprojects {
    if (project.name == "arcore_flutter_plugin") {
        afterEvaluate {
            pluginManager.withPlugin("com.android.library") {
                extensions.configure<com.android.build.gradle.LibraryExtension> {
                    namespace = "com.github.giandifra.arcore_flutter_plugin"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
