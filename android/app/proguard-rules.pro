# ONNX Runtime — called via JNI from native code (flutter_wake_word / DaVoice)
-keep class ai.onnxruntime.** { *; }

# TensorFlow Lite — referenced by tflite_flutter plugin
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
