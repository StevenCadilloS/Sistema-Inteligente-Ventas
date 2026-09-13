import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Datos de la clave de firma. El archivo NO esta en git (ver android/.gitignore):
// en CI lo escribe el workflow a partir de los secretos del repositorio.
val propiedadesFirma = Properties()
val archivoFirma = rootProject.file("key.properties")
val hayClavePropia = archivoFirma.exists()
if (hayClavePropia) {
    propiedadesFirma.load(FileInputStream(archivoFirma))
}

android {
    namespace = "com.tuapp.tienda_adaptativa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tuapp.tienda_adaptativa"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // CameraX + ML Kit Face Detection + TensorFlow Lite (ver README)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hayClavePropia) {
                keyAlias = propiedadesFirma.getProperty("keyAlias")
                keyPassword = propiedadesFirma.getProperty("keyPassword")
                storeFile = file(propiedadesFirma.getProperty("storeFile"))
                storePassword = propiedadesFirma.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Con clave propia, todas las APK comparten firma y una se instala
            // encima de la anterior. Firmando con la de depuracion no: esa clave
            // se genera sola en cada maquina que no la tenga, y cada runner de CI
            // arranca limpio -- cada build salia con una firma distinta y Android
            // rechazaba la actualizacion con "conflicto con un paquete", que es
            // justo lo que rompia el aviso de actualizacion de la app.
            //
            // Sin key.properties (un clon recien hecho, sin los secretos) se
            // vuelve a la de depuracion para que `flutter build apk` no falle.
            signingConfig = if (hayClavePropia) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // ML Kit descubre sus ComponentRegistrar mediante reflexión.
            // Con R8 activo en AGP 9, esos constructores se eliminan y la APK
            // release se cierra al iniciar aunque la variante debug funcione.
            isMinifyEnabled = false
            isShrinkResources = false
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
    // Modulo nativo: camara, deteccion facial y clasificacion de emociones (ver README)
    val cameraxVersion = "1.3.4"
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")

    implementation("com.google.mlkit:face-detection:16.1.6")
    // 2.16.1 (no 2.14.0): tensorflow-lite y tensorflow-lite-api 2.14.0
    // declaran el mismo namespace de manifest, lo que rompe el manifest
    // merger con AGP moderno. 2.16.1 lo corrige; misma API (org.tensorflow.lite.*).
    implementation("org.tensorflow:tensorflow-lite:2.16.1")

    // Pruebas JVM del modulo nativo (no requieren emulador ni dispositivo):
    // EmotionProcessor es logica pura y se puede verificar aqui.
    // Ejecutar con: ./gradlew :app:testDebugUnitTest
    testImplementation("junit:junit:4.13.2")
}
