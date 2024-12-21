import 'package:flutter/material.dart';
import 'package:kundalikcom_mobile/database.dart';
import 'capcha/kundalikcom_func.dart';
import 'package:permission_handler/permission_handler.dart';
import "main.dart";
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

class EditDialog extends StatefulWidget {
  final String initialName;
  final String initialLogin;
  final String initialPassword;
  final Function state_func;

  const EditDialog({
    super.key,
    required this.initialName,
    required this.initialLogin,
    required this.initialPassword,
    required this.state_func,
  });

  @override
  _EditDialogState createState() => _EditDialogState(state_func: state_func);
}

class _EditDialogState extends State<EditDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Function state_func;

  _EditDialogState({required this.state_func});

  bool isDeleteButtonDisabled = false;
  bool isSaveButtonDisabled = false;
  @override
  void initState() {
    super.initState();
    nameController.text = widget.initialName;
    loginController.text = widget.initialLogin;
    passwordController.text = widget.initialPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Taxrirlash",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildTextField(nameController, "Ism familiya"),
            const SizedBox(height: 10),
            _buildTextField(loginController, "Login", readOnly: true),
            const SizedBox(height: 10),
            _buildTextField(passwordController, "Parol"),
            const SizedBox(height: 20),
            _buildButtonRow(context),
          ],
        ),
      ),
    );
  }

  TextField _buildTextField(TextEditingController controller, String labelText,
      {bool readOnly = false, bool obscureText = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Row _buildButtonRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isDeleteButtonDisabled
                ? null
                : () async {
                    setState(() {
                      isDeleteButtonDisabled = true;
                    });
                    // O'chirish funksiyasi
                    await _deleteFunction();
                    if (mounted) {
                      setState(() {
                        isDeleteButtonDisabled = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("O'chirish"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isSaveButtonDisabled
                ? null
                : () async {
                    setState(() {
                      isSaveButtonDisabled = true;
                    });
                    // Saqlash funksiyasi
                    await _saveFunction();
                    if (mounted) {
                      setState(() {
                        isSaveButtonDisabled = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Saqlash"),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteFunction() async {
    DatabaseHelper().deleteLogin(loginController.text.trim());
    try {
      state_func(() {});
    } catch (e) {}
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
        'O\'chirildi',
        style: TextStyle(color: Color.fromRGBO(255, 60, 0, 1)),
      ),
    ));
    await Future.delayed(const Duration(seconds: 1)); // Asinxron operatsiya
  }

  Future<void> _saveFunction() async {
    DatabaseHelper().updateLogin(loginController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim());
    try {
      state_func(() {});
    } catch (e) {}
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
        'Ma\'lumotlar saqlandi',
        style: TextStyle(color: Color.fromRGBO(115, 255, 0, 1)),
      ),
    ));
    await Future.delayed(const Duration(seconds: 1)); // Asinxron operatsiya
  }
}

// Function to show the edit dialog
void showEditPopup(BuildContext context, String initialName,
    String initialLogin, String initialPassword, Function stateFunc) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return EditDialog(
        initialName: initialName,
        initialLogin: initialLogin,
        initialPassword: initialPassword,
        state_func: stateFunc,
      );
    },
  );
}

class AddDialog extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(
      String name, String login, String password, BuildContext context) onAdd;
  final VoidCallback onCancel;

  const AddDialog({super.key, required this.onAdd, required this.onCancel});

  @override
  _AddDialogState createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isButtonDisabled = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Qo'shish",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _buildTextField("Ism familiya", nameController),
            const SizedBox(height: 10),
            _buildTextField("Login", loginController),
            const SizedBox(height: 10),
            _buildTextField("Parol", passwordController),
            const SizedBox(height: 20),
            _buildAddCancelButtonRow(context),
          ],
        ),
      ),
    );
  }

  TextField _buildTextField(String labelText, TextEditingController controller,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: obscureText,
    );
  }

  Row _buildAddCancelButtonRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isButtonDisabled
                ? null
                : () async {
                    setState(() {
                      isButtonDisabled = true;
                    });
                    String login = loginController.text;
                    String password = passwordController.text;
                    String name = nameController.text;
                    if (name.trim() != "" &&
                        login.trim() != "" &&
                        password.trim() != "") {
                      var result =
                          await widget.onAdd(name, login, password, context);
                      if (mounted) {
                        // Muvaffaqiyatli qo'shishdan keyin tozalash
                        if (result['success']) {
                          nameController.clear();
                          loginController.clear();
                          passwordController.clear();
                        }
                      }
                    }
                    setState(() {
                      isButtonDisabled = false;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Qo'shish"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isButtonDisabled ? null : widget.onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(100, 218, 68, 0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              "Yopish",
              style: TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}

void showAddPopup(BuildContext context, Function stateFunc) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AddDialog(
        onAdd: (name, login, password, popupContext) async {
          var result = await loginUser(login, password);
          if (result['success']) {
            String res = await DatabaseHelper().addLogin(name, login, password);
            if (res == "") {
              showSuccesXabari(popupContext);
              try {
                stateFunc(() {});
              } catch (e) {}
            } else {
              showtushuntirishXabari(context, "Login qo'shilmadi", res);
            }
          } else {
            print(result);
            showtushuntirishXabari(
                context, "Login qo'shilmadi", result["message"]);
          }
          return result; // Return result here
        },
        onCancel: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      );
    },
  );
}

// To'lov xabari dialogini ko'rsatish uchun funksiya
void showPaymentDialog(BuildContext context,
    {required bool isSuccess, required String message_text}) {
  String title =
      isSuccess ? "To'lov amalga oshirildi" : "To'lov amalga oshirilmadi";
  String message = isSuccess
      ? "Sizning to'lovingiz muvaffaqiyatli amalga oshirildi."
      : (message_text == ""
          ? "Sizning to'lovingiz amalga oshirilmadi. Iltimos, qayta urinib ko'ring."
          : message_text);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(
              color: Color.fromRGBO(
                  isSuccess ? 0 : 255, isSuccess ? 180 : 0, 0, 1)),
        ),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true)
                  .pop(); // Dialogni yopish
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

void showConfirmationDialog(BuildContext context, String totalPrice,
    int monthsCount, Function stateFunc) {
  showDialog(
    context: context,
    builder: (
      BuildContext context,
    ) {
      return AlertDialog(
        title: const Text("To'lov amalga oshirilsinmi?"),
        content: Text(
            "Jami: $totalPrice so'm\nSiz to'lovni amalga oshirishni xohlaysizmi?"),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () async {
              Dio dio = Dio();
              String token = await DatabaseHelper().getData("token") ?? "";
              try {
                var response = await dio.post(
                  "https://api.projectsplatform.uz/kundalikcom/buy_api_mobile",
                  data: {'token': token, 'months_count': monthsCount},
                );
                if (response.data["how"]) {
                  // To'lov amalga oshiriladi
                  Navigator.of(context).pop(); // Dialogni yopish
                  try {
                    stateFunc(() {});
                  } catch (e) {}
                  showPaymentDialog(context,
                      isSuccess: true,
                      message_text: ""); // Muvaffaqiyatli to'lov xabari
                } else {
                  Navigator.of(context).pop(); // Dialogni yopish
                  showPaymentDialog(context,
                      isSuccess: false, message_text: response.data["message"]);
                }
              } on DioException {
                Navigator.of(context).pop(); // Dialogni yopish
                showPaymentDialog(context, isSuccess: false, message_text: "");
              }
            },
            child: const Text("Ha"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialogni yopish
            },
            child: const Text("Yo'q"),
          ),
        ],
      );
    },
  );
}

void showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Hisobingizdan chiqasizmi?"),
        content: const Text("Siz hisobingizdan chiqmoqchimisiz?"),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper()
                  .logout(); // Foydalanuvchini tizimdan chiqarish

              Navigator.of(context).pop(); // Dialogni yopish
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainPage()),
              ); // Foydalanuvchini bosh sahifaga qaytarish
            },
            child: const Text(
              "chiqish",
              style: TextStyle(color: Color.fromRGBO(255, 0, 0, 1)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialogni yopish
            },
            child: const Text("Yo'q"),
          ),
        ],
      );
    },
  );
}

void showSuccesXabari(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Muvaffaqiyatli qo'shildi",
            style: TextStyle(color: Color.fromRGBO(0, 200, 50, 1))),
        content: const Text("1 ta login va parol ma'lumotlari qo'shildi",
            style: TextStyle(color: Color.fromRGBO(0, 30, 0, 1))),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialogni yopish
            },
            child: const Text("Tushunarli"),
          ),
        ],
      );
    },
  );
}

void showRunSuccesXabari(BuildContext context, String foiz, String jami,
    String kirildi, String kirilmadi) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Login qilish yakunlandi\n $foiz"),
        content: Text(kirilmadi == "0"
            ? "Jami $jami tadan hammasiga kirildi."
            : "Jami $jami tadan $kirildi tasiga kirildi.\n$kirilmadi ta xato parol mavjud.\nXatoliklarni \"Ma'lumotlar\" bo'limidan bartaraf etishingiz mumkin."),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialogni yopish
            },
            child: Text(kirilmadi == "0" ? "Yopish" : "Tushunarli"),
          ),
        ],
      );
    },
  );
}

void showtushuntirishXabari(BuildContext context, String title, String text) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialogni yopish
            },
            child: const Text("Tushunarli"),
          ),
        ],
      );
    },
  );
}

void showError(BuildContext context, String title, String text) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(color: Color.fromARGB(255, 255, 90, 0)),
        ), // `const` olib tashlandi
        content: Text(text), // `const` olib tashlandi
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialogni yopish
            },
            child: const Text("Yopish"),
          ),
        ],
      );
    },
  );
}

// Faylga ruxsat olish
Future<void> checkAndRequestPermission() async {
  // Agar ruxsat berilmagan bo'lsa, foydalanuvchidan so'rash
  PermissionStatus status = await Permission.storage.request();

  if (status.isGranted) {
    print("Ruxsat berildi!");
  } else if (status.isDenied) {
    print("Ruxsat rad etildi!");
  } else if (status.isPermanentlyDenied) {
    // Foydalanuvchi ruxsatni rad etgan va tizimda ruxsatni qayta so'rash mumkin emas
    openAppSettings(); // Ilova sozlamalarini ochish
  }
}

void balance_tuldirish() async {
  List<String> list = [
    "tg://resolve?domain=KundalikCom_avto_login1",
    "tg://resolve?domain=KundalikCom_avto_login2"
  ];

  // Telegram akkauntiga yo'naltirish
  Random random = Random();
  int randomIndex = random.nextInt(list.length);
  String randomurl = list[randomIndex];

  // URLni ochish uchun launchUrl foydalanish
  Uri uri = Uri.parse(randomurl);
  print(uri);
  await launchUrl(uri);
}
