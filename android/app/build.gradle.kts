import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clave de subida para firmar el release de verdad (ver `key.properties`,
// gitignoreado — cada quien que clone el repo genera la suya con
// `keytool`). Sin esto, el build de release caería al signing de debug
// de más abajo: funciona para probar, pero nadie podría *actualizar* una
// instalación real (Android rechaza instalar una firma distinta encima).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val tieneKeystoreDeRelease = keystorePropertiesFile.exists()
if (tieneKeystoreDeRelease) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.appalabanzas.app_alabanzas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (NotificacionesService) lo exige —
        // sin esto, Gradle rechaza la dependencia con "requires core
        // library desugaring to be enabled".
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.appalabanzas.app_alabanzas"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (tieneKeystoreDeRelease) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Con `key.properties` (clave real) firma el release de
            // verdad; sin eso — un clon nuevo del repo sin el keystore —
            // cae a la clave debug para que igual se pueda compilar y
            // probar localmente.
            signingConfig = if (tieneKeystoreDeRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Versión mínima que exige flutter_local_notifications — ver el
    // `coreLibraryDesugaringEnabled` de arriba.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
