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
    
    // Auto configuration for older plugins to satisfy AGP 8 and resolve SDK compatibility issues
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val clazz = androidExt.javaClass
                
                // 1. Force SDK 34 to resolve lStar resource errors
                val setCompileSdkVersion = clazz.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                setCompileSdkVersion.invoke(androidExt, 34)

                val getDefaultConfig = clazz.getMethod("getDefaultConfig")
                val defaultConfig = getDefaultConfig.invoke(androidExt)
                val setTargetSdkVersion = defaultConfig.javaClass.getMethod("targetSdkVersion", Int::class.javaPrimitiveType)
                setTargetSdkVersion.invoke(defaultConfig, 34)

                // 2. Auto namespace assignment
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
