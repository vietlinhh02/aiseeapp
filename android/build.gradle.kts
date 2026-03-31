allprojects {
    repositories {
        google()
        mavenCentral()
        // DaVoice: AAR com.davoice:keyworddetection trong pub-cache (Gradle resolve từ :app cần repo này).
        val pubDev = file("${System.getProperty("user.home")}/.pub-cache/hosted/pub.dev")
        val wakeLibDirs = pubDev.listFiles { f: java.io.File ->
            f.isDirectory &&
                f.name.startsWith("flutter_wake_word-") &&
                f.resolve("android/libs/com/davoice").isDirectory
        }
        wakeLibDirs?.maxByOrNull { it.name }?.resolve("android/libs")?.let { libs ->
            maven {
                url = libs.toURI()
            }
        }
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
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
