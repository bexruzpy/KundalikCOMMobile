import 'package:flutter/material.dart';
import 'database.dart';
import 'utils.dart';
import 'package:dio/dio.dart';

class LoginPage extends StatefulWidget {
  final Function onLogin; // Callback funksiyasi

  const LoginPage({super.key, required this.onLogin});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController smsCodeController = TextEditingController();
  bool _isObscure = true; // Parolni ko'rish holatini boshqarish

  void login(BuildContext context) async {
    Dio dio = Dio();
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      try {
        var response = await dio.post(
          "https://api.projectsplatform.uz/accounts/login",
          data: {'username': username, 'password': password},
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Telegram Bot orqali tasdiqlash code yuborildi'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              '! Username yoki parol bo\'sh bo\'lmasligi kerak',
              style: TextStyle(color: Color.fromRGBO(255, 60, 0, 1)),
            ),
          ));
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Username yoki parol xato kiritildi\nqayta urinib ko\'ring!',
              style: TextStyle(color: Color.fromRGBO(255, 60, 0, 1)),
            ),
          ));
        } else {
          showtushuntirishXabari(
            context,
            "Internet mavjud emas",
            "Internetga ulaning",
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          '! Username yoki parol bo\'sh bo\'lmasligi kerak',
          style: TextStyle(color: Color.fromARGB(255, 255, 140, 0)),
        ),
      ));
    }
  }

  void check(BuildContext context) async {
    Dio dio = Dio();
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      int smsCode;
      try {
        smsCode = int.parse(smsCodeController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Sms code faqat raqamlardan iborat bo\'lishi kerak',
            style: TextStyle(color: Color.fromRGBO(255, 60, 0, 1)),
          ),
        ));
        return;
      }
      try {
        var response = await dio.post(
          "https://api.projectsplatform.uz/accounts/check-login-code",
          data: {'username': username, 'password': password, "code": smsCode},
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> allData = response.data as Map<String, dynamic>;
          Map<String, String> stringData =
              allData.map((key, value) => MapEntry(key, value.toString()));

          var response2 = await dio.post(
              'https://api.projectsplatform.uz/kundalikcom/check_mobile',
              data: {
                'token': response.data["token"],
                'device_id': await DatabaseHelper().getData("device_id"),
              });

          if (response2.statusCode == 200 && response2.data["how"]) {
            final Map<String, dynamic> decodedData2 = response2.data;
            final Map<String, String> data2 = decodedData2
                .map((key, value) => MapEntry(key, value.toString()));

            await DatabaseHelper().setDatas(data2);
            await DatabaseHelper().setDatas(stringData);
            widget.onLogin();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Hisobingizga muvaffaqiyatli kirdingiz'),
            ));
          } else {
            showtushuntirishXabari(
                context, "Hisobga kirilmadi", response2.data["message"]);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Username yoki parol xato kiritildi\nqayta urinib ko\'ring!',
              style: TextStyle(color: Color.fromRGBO(255, 60, 0, 1)),
            ),
          ));
        }
      } on DioException catch (e) {
        print(e);
        if (e.response?.statusCode == 400) {
          showtushuntirishXabari(
            context,
            "Tasdiqlash kodi xato",
            "Telegram botimizdan kelgan 6 xonali sms kodni kiritishingiz kerak",
          );
        } else {
          showtushuntirishXabari(
            context,
            "Internet mavjud emas",
            "Internetga ulaning",
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          '! Username yoki parol bo\'sh bo\'lmasligi kerak',
          style: TextStyle(color: Color.fromARGB(255, 255, 140, 0)),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(217, 217, 217, 1),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            width: 500,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "KundalikCOM\nauto login",
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromRGBO(128, 70, 255, 1),
                    fontWeight: FontWeight.bold,
                    fontFamily: "OpenSans-Bold",
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "powered by Projects Platform",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color.fromRGBO(27, 0, 146, 1),
                    fontFamily: "OpenSans-Light",
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.17),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color.fromRGBO(0, 13, 95, 0.53),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Hisobga kirish",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontFamily: "OpenSans-Bold",
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: "Username",
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Parol kiritish maydoni
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText: "Password",
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                        ),
                        obscureText: _isObscure,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: smsCodeController,
                              decoration: InputDecoration(
                                hintText: "SMS kod",
                                filled: true,
                                fillColor: Colors.transparent,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: () {
                                login(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(33, 30, 55, 1),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text(
                                "Kodni\nolish",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          check(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(128, 70, 255, 1),
                          foregroundColor:
                              const Color.fromRGBO(255, 255, 255, 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 20),
                        ),
                        child: const Text(
                          "K I R I SH",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
