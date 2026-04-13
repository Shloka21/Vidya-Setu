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
    
    // Auto namespace assignment for older plugins to satisfy AGP 8
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val clazz = androidExt.javaClass
                val getNamespace = clazz.getMethod("getNamespace")
                if (getNamespace.invoke(androidExt) == null) {
                    val manifest = project.file("src/main/AndroidManifest.xml")
                    if (manifest.exists()) {
                        val content = manifest.readText()
                        val matcher = java.util.regex.Pattern.compile("package=\"([^\"]+)\"").matcher(content)
                        if (matcher.find()) {
                            val setNamespace = clazz.getMethod("setNamespace", String::class.java)
                            setNamespace.invoke(androidExt, matcher.group(1))
                        }
                    }
                }
            } catch (e: Exception) {}
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
