# Raqam tanib olish uchun kerak bo'lgan asosiy qoidalar
-keep class com.google.mlkit.vision.text.** { *; }

# Xitoy, yapon, koreys va boshqa tillar uchun ishlatilmaydigan tanib olish sinflarini saqlamaslik
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
