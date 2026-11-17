# Pertahankan simbol JNI/FFI TensorFlow Lite & LiteRT pada build release
-keep class org.tensorflow.lite.** { *; }
-keep class com.google.ai.edge.litert.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn com.google.ai.edge.litert.**
