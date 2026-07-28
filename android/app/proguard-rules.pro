# ------------------------------------------------------------------
# ProGuard/R8 rules — Faixa Amarela (Flutter)
# O engine do Flutter e a maioria dos plugins já embutem consumer
# ProGuard rules; aqui ficam apenas as regras do app e proteções
# conhecidas necessárias para R8 full mode.
# ------------------------------------------------------------------

-dontwarn org.slf4j.impl.StaticLoggerBinder

# Métodos nativos (JNI) nunca podem ser renomeados/removidos.
-keepclasseswithmembernames class * { native <methods>; }

# Registrador de plugins gerado pelo Flutter (chamado via reflexão
# pelo embedding nativo).
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# MainActivity e classes do app referenciadas pelo AndroidManifest.
-keep class com.faixaamarela.app.** { *; }

# Firebase / Google Play services — warnings benignos conhecidos.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# flutter_local_notifications + desugaring: warnings de APIs java.time
# já cobertas pelo desugar_jdk_libs.
-dontwarn java.time.**
-dontwarn com.dexterous.**

# Gson/JSON reflexivo usado por alguns plugins legados (harmless se não houver).
-keepattributes Signature, *Annotation*, EnclosingMethod
