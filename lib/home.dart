import 'package:flutter/material.dart';
import 'database.dart';
import 'capcha/kundalikcom_func.dart';
import 'utils.dart';
import 'package:dio/dio.dart'; // Dio import qilindi

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isNotRunned = true;
  Future<List<Map<String, dynamic>>> fetchReports() async {
    List<Map<String, dynamic>> result = [];
    for (String day in getLastSevenDays()) {
      var data = await DatabaseHelper().getData(day);
      if (data != null) {
        result.add({"date": day, "data": data});
      }
    }
    return result;
  }

  Future<Map<String, String>> fetchTodayReport() async {
    String today = getTodayWeekdayName();
    var data = await DatabaseHelper().getData(today);
    if (data != null) {
      var parts = data.split('|');
      return {"percentage": parts[3], "loginInfo": "${parts[0]}/${parts[2]}"};
    } else {
      return {"percentage": "0%", "loginInfo": "0/0"};
    }
  }

  Future<void> runLoginProcess() async {
    String holat = await getAllData();
    if (!isNotRunned || holat != "") {
      if (holat != "") {
        showtushuntirishXabari(context, "!", holat);
      }
      return;
    }
    final logins = await DatabaseHelper().getLogins();
    final int num = logins.length;
    var n = 0;

    String today = getTodayWeekdayName();
    if (num != 0) {
      await DatabaseHelper()
          .setData(today, '$n|${num - n}|$num|${(100 * n) ~/ num}%');
    } else {
      await DatabaseHelper().setData(today, '$n|${num - n}|$num|0%');
    }
    if (mounted) {
      setState(() {
        isNotRunned = false;
      });
    }
    for (var entry in logins.entries) {
      final login = entry.key;
      final password = entry.value['password'];
      final result = await loginUser(login, password);
      var h = -1;
      for (int j = 0; j < 10; j++) {
        if (result["success"]) {
          h = 1;
          if (num != 0) {
            await DatabaseHelper()
                .setData(today, '$n|${num - n}|$num|${(100 * n) ~/ num}%');
          } else {
            await DatabaseHelper().setData(today, '$n|${num - n}|$num|0%');
          }
          if (mounted) {
            setState(() {
              isNotRunned = false;
            });
          }
          await DatabaseHelper().updateLogin(login, holat: 1);
          break;
        } else if (result["message"] == "Login yoki parol xato") {
          h = 0;
          await DatabaseHelper().updateLogin(login, holat: 0);
          break;
        }
      }
      if (h < 0) {
        h = 1;
      }
      n += h;
    }
    if (num != 0) {
      await DatabaseHelper()
          .setData(today, '$n|${num - n}|$num|${(100 * n) ~/ num}%');
    } else {
      await DatabaseHelper().setData(today, '$n|${num - n}|$num|0%');
    }
    // Hisobotlarni yangilash uchun setState chaqiramiz
    if (mounted) {
      setState(() {
        isNotRunned = true;
      });
      if (num != 0) {
        showRunSuccesXabari(
          context,
          '${(100 * n) ~/ num}%',
          '$num',
          '$n',
          '${num - n}',
        );
      } else {
        showRunSuccesXabari(
          context,
          '0%',
          '$num',
          '$n',
          '${num - n}',
        );
      }
    }
  }

  Future<String> getAllData() async {
    final token = await DatabaseHelper().getData("token"); // Tokenni olish
    final dio = Dio();

    try {
      final response2 = await dio.post(
        'https://api.projectsplatform.uz/kundalikcom/check_mobile',
        data: {
          'token': token,
          'device_id': await DatabaseHelper().getData("device_id"),
        },
      );
      if (response2.statusCode == 200 && response2.data["how"]) {
        if (response2.data["size"] > 0) {
          return "";
        }
        return "Sizning letsenziyangiz tugagan xarid amalga oshiring";
      } else {
        print(response2.data["message"]);
        return response2.data["message"];
      }
    } catch (e) {
      return "Internetga ulanmagansiz";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDBDBDB), // Background color
      child: Column(
        children: [
          // Hisobot bo'limi
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Xatolik yuz berdi'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Hisobotlar mavjud emas'));
                } else {
                  final reports = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      children: reports.map((report) {
                        return reportBox(
                          report['date'],
                          report['data'].split('|')[0],
                          report['data'].split('|')[1],
                          report['data'].split('|')[2],
                          report['data'].split('|')[3], // Foiz qismi
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ),

          // Run tugmasi va bugungi hisobot ko'rsatkichlari
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FutureBuilder<Map<String, String>>(
                  future: fetchTodayReport(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Xatolik yuz berdi'));
                    } else {
                      final todayReport = snapshot.data!;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            todayReport["percentage"] ?? "0%",
                            style: const TextStyle(
                              color: Color(0xFFFF5A00),
                              fontSize: 28,
                            ),
                          ),
                          Text(
                            todayReport["loginInfo"] ?? "0/0",
                            style: const TextStyle(
                              color: Color(0xFF1B1F3E),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    await runLoginProcess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(
                        isNotRunned ? 255 : 60, 7, isNotRunned ? 7 : 200, 65),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                  ),
                  child: const Text('R U N',
                      style: TextStyle(
                          fontSize: 24,
                          color: Color.fromRGBO(255, 255, 255, 1))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget reportBox(String title, String n, String nx, String num, String foiz) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF9D9DFF).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              foiz,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.green, fontSize: 36, fontFamily: "Times"),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Times",
                    fontSize: 24,
                  ),
                ),
                Text(
                  "Jami: $num\nKirilgan: $n\nParoli xatolari: $nx",
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getTodayWeekdayName() {
    DateTime today = DateTime.now();

    switch (today.weekday) {
      case 1:
        return "Dushanba";
      case 2:
        return "Seshanba";
      case 3:
        return "Chorshanba";
      case 4:
        return "Payshanba";
      case 5:
        return "Juma";
      case 6:
        return "Shanba";
      case 7:
        return "Yakshanba";
      default:
        return "Noma'lum kun";
    }
  }

  List<String> getLastSevenDays() {
    DateTime today = DateTime.now();
    List<String> daysOfWeek = [
      "Yakshanba",
      "Dushanba",
      "Seshanba",
      "Chorshanba",
      "Payshanba",
      "Juma",
      "Shanba"
    ];

    List<String> lastSevenDays = [];
    for (int i = 0; i < 7; i++) {
      DateTime day = today.subtract(Duration(days: i));
      lastSevenDays.add(daysOfWeek[day.weekday % 7]);
    }

    return lastSevenDays;
  }
}
