allprojects {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://jitpack.io")
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
    // Older Flutter plugins can still rely on the AndroidManifest package
    // instead of the AGP 8+ namespace property. Backfill it here so we do not
    // need to patch files inside Pub Cache on every machine.
    pluginManager.withPlugin("com.android.library") {
        val androidExtension = extensions.findByName("android") ?: return@withPlugin
        val getNamespace =
            androidExtension.javaClass.methods.firstOrNull { it.name == "getNamespace" }
        val setNamespace =
            androidExtension.javaClass.methods.firstOrNull { it.name == "setNamespace" }
        val currentNamespace = getNamespace?.invoke(androidExtension) as? String
        if (currentNamespace.isNullOrBlank()) {
            setNamespace?.invoke(androidExtension, project.group.toString())
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
