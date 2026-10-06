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
// Some plugins (mp_audio_stream) pin compileSdk 31, minSdk 16 and an old NDK,
// which current AndroidX and the NDK reject. Align every Android library module with
// the app's SDK and NDK. Must be registered before evaluationDependsOn below.
subprojects {
    afterEvaluate {
        val app = project(":app").extensions
            .getByType<com.android.build.api.dsl.ApplicationExtension>()
        extensions.findByType<com.android.build.api.dsl.LibraryExtension>()?.apply {
            compileSdk = app.compileSdk
            ndkVersion = app.ndkVersion
            defaultConfig.minSdk = app.defaultConfig.minSdk
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
