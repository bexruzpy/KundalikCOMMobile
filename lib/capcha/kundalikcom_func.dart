import 'dart:io'; // File IO uchun
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';

// CAPTCHA rasmidan matnni olish
Future<String> toStrFromFile(String imagePath) async {
  final InputImage inputImage = InputImage.fromFilePath(imagePath);
  final TextRecognizer textRecognizer = GoogleMlKit.vision.textRecognizer();
  try {
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    String result = recognizedText.text;
    return result.isNotEmpty
        ? result.replaceAll(RegExp(r'\D'), '') // Faqat raqamlarni olish
        : '';
  } catch (e) {
    return 'Xatolik: $e';
  } finally {
    textRecognizer.close();
  }
}

Future<Map<String, dynamic>> loginUserCheck(
    Map<String, String> loginData) async {
  String login = loginData['login'] ?? '';
  String parol = loginData['parol'] ?? '';
  String capchaId = loginData['capcha_id'] ?? '';
  String capchaValue = loginData['capcha_value'] ?? '';

  try {
    // Capcha mavjud bo'lsa
    if (capchaId != "") {
      var response = await http.post(
        Uri.parse("https://login.emaktab.uz/"),
        body: {
          "exceededAttempts": "True",
          "login": login,
          "password": parol,
          "Captcha.Input": capchaValue,
          "Captcha.Id": capchaId,
        },
      );

      var responseBody = response.body;
      // Cookie'larni olish
      String? rawCookies = response.headers['set-cookie'];
      http.Response getResponse;
      if (rawCookies != null) {
        // GET so'rov - cookie'larni ishlatib
        getResponse = await http.get(
          Uri.parse("https://emaktab.uz"), // GET URL'ni shu yerga yozing
          headers: {
            "Cookie": rawCookies, // Cookie'larni headerga qo'shamiz
          },
        );
      } else {
        // GET so'rov - cookie'larni ishlatib
        getResponse = await http.get(
          Uri.parse("https://emaktab.uz"), // GET URL'ni shu yerga yozing
        );
      }
      var getResponseBody = getResponse.body;
      print(getResponseBody);
      if (getResponseBody.contains("Chiqish") ||
          getResponseBody
              .contains("&#x41F;&#x43E;&#x43C;&#x43E;&#x449;&#x44C;")) {
        return {"success": true, "how": true};
      } else if (responseBody
          .contains("Parol yoki login notoʻgʻri koʻrsatilgan")) {
        return {
          "success": false,
          "how": false,
          "capcha": false,
          "message": "Login yoki parol xato"
        };
      } else {
        // Capcha ID va URL ni qaytarish
        var cookies = response.headers['set-cookie'] ?? '';
        var capchaId =
            Uri.decodeComponent(cookies.split('sst=')[1]).split('|')[0];
        var url = "https://login.emaktab.uz/captcha/True/$capchaId";

        return {
          "success": false,
          "how": false,
          "capcha": true,
          "capcha_id": capchaId,
          "url": url,
          "message": "Rasmdagi raqamlarni xato kiritdingiz"
        };
      }
    }

    // Capcha talab qilinmaydigan holat
    var response = await http.post(
      Uri.parse("https://login.emaktab.uz"),
      body: {
        "exceededAttempts": "False",
        "login": login,
        "password": parol,
      },
    );

    var responseBody = response.body;
    // Cookie'larni olish
    String? rawCookies = response.headers['set-cookie'];
    http.Response getResponse;
    if (rawCookies != null) {
      // GET so'rov - cookie'larni ishlatib
      getResponse = await http.get(
        Uri.parse("https://emaktab.uz"), // GET URL'ni shu yerga yozing
        headers: {
          "Cookie": rawCookies, // Cookie'larni headerga qo'shamiz
        },
      );
    } else {
      // GET so'rov - cookie'larni ishlatib
      getResponse = await http.get(
        Uri.parse("https://emaktab.uz"), // GET URL'ni shu yerga yozing
      );
    }
    var getResponseBody = getResponse.body;
    print(getResponseBody);
    if (getResponseBody.contains("Chiqish") ||
        getResponseBody
            .contains("&#x41F;&#x43E;&#x43C;&#x43E;&#x449;&#x44C;")) {
      return {"success": true, "how": true};
    } else if (responseBody
            .contains("Parol yoki login notoʻgʻri koʻrsatilgan") ||
        responseBody.contains(
            "Неправильно указан пароль или логин. Попробуйте еще раз.")) {
      return {
        "success": false,
        "how": false,
        "capcha": false,
        "message": "Login yoki parol xato"
      };
    } else {
      var cookies = response.headers['set-cookie'] ?? '';
      var capchaId =
          Uri.decodeComponent(cookies.split('sst=')[1]).split('|')[0];
      var url = "https://login.emaktab.uz/captcha/True/$capchaId";

      return {
        "success": false,
        "how": false,
        "capcha": true,
        "capcha_id": capchaId,
        "url": url,
      };
    }
  } catch (e) {
    print(e);
    return {
      "success": false,
      "how": false,
      "capcha": false,
      "message": "Nimadur xato ketdi qayta urinib ko'ring"
    };
  }
}

// CAPTCHA rasmni saqlash va matn olish
Future<String> downloadAndExtractCaptchaText(var captchaUrl) async {
  var client = http.Client();
  try {
    var captchaResponse = await client.get(Uri.parse(captchaUrl));
    if (captchaResponse.statusCode == 200) {
      // Foydalanuvchi telefonidagi xotiraga faylni saqlash
      Directory appDocDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDocDir.path}/captcha.png';
      File file = File(filePath);
      await file.writeAsBytes(captchaResponse.bodyBytes);

      // Rasmni o'qish
      img.Image? image = img.decodeImage(captchaResponse.bodyBytes);
      if (image != null) {
        int height = image.height;
        int width = image.width;

        // Yuqori va pastga 4px oq bo'shliq qo'shish
        img.Image extendedImage = img.Image(
            width: width, height: height + 8); // Yangi bo'shliq qo'shamiz

        // Oq rangni (255, 255, 255) piksel sifatida to'ldiramiz
        for (int y = 0; y < extendedImage.height; y++) {
          for (int x = 0; x < extendedImage.width; x++) {
            extendedImage.setPixel(
                x,
                y,
                img.ColorFloat16.rgb(
                    255, 255, 255)); // Oq rang bilan to'ldirish
          }
        }

        // Original rasmni yangi rasmga joylashtirish
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            extendedImage.setPixel(x, y + 4, image.getPixel(x, y));
          }
        }

        // Yangi rasmni saqlash
        await file.writeAsBytes(img.encodePng(extendedImage));

        // CAPTCHA rasmidan matnni olish
        String captchaText = await toStrFromFile(filePath);
        return captchaText;
      } else {
        return 'Xatolik: Rasmni o\'qishning iloji bo\'lmadi';
      }
    } else {
      return 'CAPTCHA rasmni yuklab olishda xatolik';
    }
  } catch (e) {
    return 'Xatolik: $e';
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> loginUser(String login, String password) async {
  // Dio dio = Dio();
  try {
    // Login so'rovi
    // var response = await dio.post(
    //   "https://api.projectsplatform.uz/kundalikcom/login_kundalikcom",
    //   data: {
    //     'login': login,
    //     'parol': password,
    //     "capcha_id": "",
    //     "capcha_value": ""
    //   },
    // );

    // var responseBody = response.data;
    var responseBody = await loginUserCheck({
      "login": login,
      'parol': password,
      "capcha_id": "",
      "capcha_value": ""
    });
    print(responseBody);

    if (responseBody["how"]) {
      return {'success': true, 'message': 'Muvaffaqiyatli login'};
    } else if (responseBody["capcha"]) {
      while (true) {
        String capchaValue =
            await downloadAndExtractCaptchaText(responseBody["url"]);
        // Login so'rovi
        // var response = await dio.post(
        //   "https://api.projectsplatform.uz/kundalikcom/login_kundalikcom",
        //   data: {
        //     'login': login,
        //     'parol': password,
        //     "capcha_id": responseBody["capcha_id"],
        //     "capcha_value": capchaValue
        //   },
        // );

        // var responsebodyCapcha = response.data;
        var responsebodyCapcha = await loginUserCheck({
          'login': login,
          'parol': password,
          "capcha_id": responseBody["capcha_id"],
          "capcha_value": capchaValue
        });
        if (responsebodyCapcha["how"]) {
          return {
            'success': true,
            'message': 'Login muvaffaqqiyatli qo\'shildi'
          };
        } else if (responsebodyCapcha["capcha"] == false) {
          return {'success': false, 'message': responsebodyCapcha["message"]};
        }
        var responsebody = responsebodyCapcha;
        responsebody;
      }
    } else {
      return {'success': false, 'message': responseBody["message"]};
    }
  } on SocketException {
    return {'success': false, 'message': 'Tarmoq mavjud emas'};
  }
}
