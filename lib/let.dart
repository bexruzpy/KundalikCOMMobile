import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Dio import qilindi
import 'utils.dart';
import 'database.dart';
import 'package:flutter/services.dart'; // Clipboard uchun import qilishingiz kerak

Future<int> getPrice(int months) async {
  final dio = Dio();
  const url =
      'https://api.projectsplatform.uz/kundalikcom/price_months_mobile'; // API URL

  try {
    final response = await dio.post(
      url,
      data: {
        'months_count': months,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data; // API javobidan narxni olish
    } else {
      throw Exception('Narxni olishda xato');
    }
  } catch (e) {
    throw Exception('Xato: $e');
  }
}

Future<Map<String, dynamic>> getAllData() async {
  final token = await DatabaseHelper().getData("token"); // Tokenni olish
  final dio = Dio();

  const url =
      'https://api.projectsplatform.uz/accounts/about_account'; // Yangi API URL
  const url2 =
      'https://api.projectsplatform.uz/kundalikcom/check_mobile'; // Yangi API URL

  try {
    final response = await dio.post(
      url,
      data: {
        'token': token,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final response2 = await dio.post(
      url2,
      data: {
        'token': token,
        'device_id': await DatabaseHelper().getData("device_id"),
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    if (response2.statusCode == 200) {
      final Map<String, dynamic> decodedData2 = response2.data;
      final Map<String, String> data2 =
          decodedData2.map((key, value) => MapEntry(key, value.toString()));

      await DatabaseHelper()
          .setDatas(data2); // API javobidan balance va end_active_date ni olish
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedData = response.data;
      final Map<String, String> data =
          decodedData.map((key, value) => MapEntry(key, value.toString()));

      await DatabaseHelper().setDatas(data);
      return data; // API javobidan balance va end_active_date ni olish
    } else {
      throw Exception('Balance ni olishda xato');
    }
  } catch (e) {
    throw Exception('Xato: $e');
  }
}

class BonusCard extends StatelessWidget {
  final String shareLink;

  const BonusCard({super.key, required this.shareLink});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(20),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sovg'a matni va ikonkasi
            const Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Color.fromARGB(
                      255, 255, 0, 0), // Yashil rangli sovg'a ikonkasi
                  size: 30,
                ),
                SizedBox(width: 8),
                Text(
                  'Bonus Sovg\'a',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50), // Yashil rang
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Sovg'a haqida matn
            const Text(
              'Ushbu xizmatimizni boshqalarga ulashing va hoziroq har bir ulashish uchun 1 oylik bonusga ega bo\'ling!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            // Button va bonus matni
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Linkni Clipboard'ga nusxalash
                    await Clipboard.setData(ClipboardData(text: shareLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Link Clipboard\'ga nusxalandi!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Nusxa olish',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.star_rate,
                      color: Colors.yellow,
                      size: 20,
                    ),
                    Text(
                      '1 oylik bonus',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 160, 0),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bonus haqida qo'shimcha ma'lumot
            const Text(
              'Ulashish orqali boshqa foydalanuvchilarni tizimga jalb qilganingizda, har bir ulashish uchun bonus sifatida 1 oy muddatida xizmatimizni bepul foydalanishingiz mumkin!',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// Bu asosiy sahifa
class LetsenziyaPage extends StatefulWidget {
  const LetsenziyaPage({super.key});

  @override
  _LetsenziyaPageState createState() => _LetsenziyaPageState();
}

class _LetsenziyaPageState extends State<LetsenziyaPage> {
  String format_price(String price) {
    String formattedNumber = '';

    // Uchta raqamdan iborat guruhlarni orqadan boshlab qo'shish
    int count = 0;
    for (int i = price.length - 1; i >= 0; i--) {
      formattedNumber = price[i] + formattedNumber;
      count++;

      // Har uchta raqamdan keyin vergul qo'shish, faqat boshida emas
      if (count % 3 == 0 && i != 0) {
        formattedNumber = ',$formattedNumber';
      }
    }

    return formattedNumber;
  }

  int selectedMonths = 0;
  int totalPrice = 0;
  int balance = 0; // Balance uchun o'zgaruvchi
  String endActiveDate = ""; // Tugash vaqti uchun o'zgaruvchi
  String oy_price = "---";
  String oy_chegirma_price = "---";
  int bonus_oy = 0;
  String share_link = "";
  // Balance ni yangilash
  void updateAllDatas() async {
    try {
      updatePrice();
      final Map<String, dynamic> allData = await getAllData();
      var userId = await DatabaseHelper().getData("id");
      if (mounted) {
        setState(() {
          share_link = "https://projectsplatform.uz/register?ref=$userId";
        });
      }
      String endactivedateData =
          await DatabaseHelper().getData("end_active_date") ?? "T";
      if (((await DatabaseHelper().getData("size")) ?? "|")[0] == "-") {
        if (mounted) {
          setState(() {
            balance = int.parse(allData['balance']); // Balance ni yangilash
            endActiveDate = "Letsenziyangiz tugagan";
          });
        }
      } else if (endactivedateData != "T") {
        List<String> dateList = endactivedateData.split("T")[0].split("-");
        if (mounted) {
          setState(() {
            balance = int.parse(allData['balance']); // Balance ni yangilash
            endActiveDate = "${dateList[2]}.${dateList[1]}.${dateList[0]}y";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            balance = int.parse(allData['balance']); // Balance ni yangilash
            endActiveDate = "";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showError(context, "Internet xatosi", "Tarmoq mavjud emas!");
      }
    }
  }

  void updatePrice() async {
    final int price = await getPrice(selectedMonths);
    final int priceD = await getPrice(1);
    final int chegirma = await getPrice(3);
    if (mounted) {
      setState(() {
        totalPrice = price;
        oy_price = format_price(priceD.toString());
        oy_chegirma_price = format_price((chegirma ~/ 3).toString());
      });
    }
  }

  @override
  void initState() {
    super.initState();
    updateAllDatas(); // Sahifa yuklanganda balance ni yangilash
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 150,
        title: SizedBox(
          height: 150,
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(5),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Litsenziya tugash vaqti',
                          style: TextStyle(fontSize: 20)),
                      Text(
                        endActiveDate,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 247, 100, 0)),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Balance:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7560CB),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${format_price(balance.toString())} so'm", // Balance ni ko'rsatish
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      balance_tuldirish(); // Balance ni yangilash
                    },
                    child: const Text("To'ldirish"),
                  ),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFDBDBDB),
          child: Column(
            children: [
              const SizedBox(height: 20),
              BonusCard(shareLink: share_link),
              Card(
                margin: const EdgeInsets.all(20),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Xarid', style: TextStyle(fontSize: 30)),
                      Text(
                        '1 oy $oy_price so’m 3 yoki 3+ oy uchun\n-20% chegirma bilan oyiga $oy_chegirma_price so\'m\nHar 9 oylik xaridingiz uchun +3 oy bonus',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              try {
                                if (mounted) {
                                  setState(() {
                                    selectedMonths = selectedMonths > 0
                                        ? selectedMonths - 1
                                        : 0;
                                    updatePrice(); // Narxni yangilash
                                  });
                                }
                              } on DioException {
                                if (mounted) {
                                  showError(context, "Internet xatosi",
                                      "Tarmoq mavjud emas!");
                                }
                              }
                            },
                          ),
                          Text(
                            "$selectedMonths oy",
                            style: const TextStyle(fontSize: 20),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              try {
                                if (mounted) {
                                  setState(() {
                                    selectedMonths += 1;
                                    updatePrice(); // Narxni yangilash
                                  });
                                }
                              } on DioException {
                                if (mounted) {
                                  showError(context, "Internet xatosi",
                                      "Tarmoq mavjud emas!");
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: selectedMonths < 3 ? "" : "Chegirma: ",
                          ),
                          TextSpan(
                            text: selectedMonths < 3 ? "" : "-20",
                            style: const TextStyle(
                                color: Color.fromARGB(255, 180, 0, 0)),
                          ),
                        ]),
                      ),
                      Text("Jami: ${format_price(totalPrice.toString())} so’m"),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: selectedMonths < 9 ? "" : "Bonus: ",
                            style: const TextStyle(fontSize: 20),
                          ),
                          TextSpan(
                            text: selectedMonths < 9
                                ? ""
                                : "+${(selectedMonths ~/ 9) * 3} oy",
                            style: const TextStyle(
                                color: Color.fromARGB(255, 0, 160, 0),
                                fontSize: 20),
                          ),
                        ]),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(128, 100, 255, 1),
                          foregroundColor:
                              const Color.fromRGBO(255, 255, 255, 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 15),
                        ),
                        onPressed: () async {
                          // Sotib olish amallari
                          try {
                            if (mounted) {
                              showConfirmationDialog(
                                  context,
                                  "${await getPrice(selectedMonths)}",
                                  selectedMonths,
                                  setState);
                            }
                          } on DioException {
                            if (mounted) {
                              showError(context, "Internet xatosi",
                                  "Tarmoq mavjud emas!");
                            }
                          }
                        },
                        child: const Text(
                          "Sotib olish",
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Tugash vaqtini ko'rsatish qismi
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(255, 100, 60, 1),
                    foregroundColor: const Color.fromRGBO(255, 255, 255, 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    fixedSize: const Size(250, 50)),
                onPressed: () {
                  if (mounted) {
                    showLogoutConfirmationDialog(context);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon va Text orasiga bo'sh joy qo'shish uchun
                    Text(
                      "Hisobdan chiqish",
                      style: TextStyle(
                        color: Colors.white, // Matn rangini oq qilib o'rnatish
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.logout,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
