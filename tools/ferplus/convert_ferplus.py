"""
Convierte FERPlus ONNX a TFLite para uso en la app Flutter.

 Modelo: emotion-ferplus-8.onnx (ONNX Model Zoo)
 Input:  (1, 1, 64, 64) - grayscale 64x64
 Output: (1, 8) - 8 emociones

 Emociones FERPlus:
   0: neutral, 1: happiness, 2: surprise, 3: sadness,
   4: anger, 5: disgust, 6: fear, 7: contempt

 Uso:
   python convert_ferplus.py
"""
import os
import sys
import subprocess
import urllib.request

ONNX_URL = "https://github.com/onnx/models/raw/main/validated/vision/body_analysis/emotion_ferplus/model/emotion-ferplus-8.onnx"
ONNX_PATH = "emotion-ferplus-8.onnx"
TFLITE_OUTPUT = "emotion_ferplus.tflite"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def install_deps():
    """Instala las dependencias necesarias para la conversion."""
    deps = ["onnx2tf", "onnx", "tf-keras", "sng4onnx", "onnx-graphsurgeon"]
    for pkg in deps:
        print(f"Instalando {pkg}...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", pkg, "-q"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def download_model():
    """Descarga el modelo FERPlus ONNX desde el Model Zoo."""
    if os.path.exists(ONNX_PATH):
        print(f"Modelo ya existe: {ONNX_PATH}")
        return

    print(f"Descargando modelo desde:\n  {ONNX_URL}")
    urllib.request.urlretrieve(ONNX_URL, ONNX_PATH)
    size_mb = os.path.getsize(ONNX_PATH) / (1024 * 1024)
    print(f"Descargado: {size_mb:.1f} MB")


def convert_to_tflite():
    """Convierte ONNX a TFLite usando onnx2tf."""
    print("\nConvirtiendo ONNX -> TFLite...")
    print("Esto puede tomar 1-3 minutos.\n")

    subprocess.check_call([
        sys.executable, "-m", "onnx2tf",
        "-i", ONNX_PATH,
        "-o", os.path.join(SCRIPT_DIR, "output"),
        "-osd",               # output SavedModel
        "-cotof",             # check output TFLite vs ONNX (float32)
    ])

    # Buscar el archivo .tflite generado
    output_dir = os.path.join(SCRIPT_DIR, "output")
    tflite_file = None
    for f in os.listdir(output_dir):
        if f.endswith("_float32.tflite"):
            tflite_file = os.path.join(output_dir, f)
            break

    if tflite_file is None:
        # Buscar cualquier .tflite
        for f in os.listdir(output_dir):
            if f.endswith(".tflite"):
                tflite_file = os.path.join(output_dir, f)
                break

    if tflite_file is None:
        print("ERROR: No se encontro archivo .tflite en la salida")
        sys.exit(1)

    # Copiar al directorio actual con nombre limpio
    import shutil
    shutil.copy2(tflite_file, TFLITE_OUTPUT)
    size_mb = os.path.getsize(TFLITE_OUTPUT) / (1024 * 1024)
    print(f"\nModelo TFLite generado: {TFLITE_OUTPUT} ({size_mb:.1f} MB)")
    return TFLITE_OUTPUT


def main():
    os.chdir(SCRIPT_DIR)
    print("=" * 60)
    print("  FERPlus ONNX -> TFLite Converter")
    print("=" * 60)
    print()
    print("Modelo: emotion-ferplus-8.onnx (ONNX Model Zoo)")
    print("Input:  (1, 1, 64, 64) - grayscale 64x64")
    print("Output: 8 emociones")
    print("  0: neutral   1: happiness  2: surprise  3: sadness")
    print("  4: anger     5: disgust    6: fear      7: contempt")
    print()

    install_deps()
    download_model()
    tflite_path = convert_to_tflite()

    print()
    print("=" * 60)
    print("  CONVERSION COMPLETADA")
    print("=" * 60)
    print()
    print(f"Archivo para tu app: {tflite_path}")
    print()
    print("Paso siguiente:")
    print(f"  Copia '{TFLITE_OUTPUT}' a:")
    print("    android/app/src/main/assets/emotion_model.tflite")
    print()
    print("NOTA: El modelo FERPlus usa:")
    print("  - Input: 64x64 grayscale (no 48x48 RGB)")
    print("  - Output: 8 clases (una mas que FER-2013)")
    print("  Deberas actualizar EmotionDetector.kt")


if __name__ == "__main__":
    main()
