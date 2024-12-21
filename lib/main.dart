import 'package:flutter/material.dart';
import 'home.dart';
import 'datas.dart';
import 'let.dart';
import 'login.dart';
import 'utils.dart';
import 'database.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ilova to'liq yuklang    anini kutadi
  await checkAndRequestPermission();
  DatabaseHelper();
  //     .setData("device_id", "46b1a2bc-a35a-493e-8934-21ee711656a5");
  runApp(const MyApp());
  // try {
  //   runApp(const MyApp());
  // } catch (e) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'KundalikCOM Mobile',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // Dastlabki sahifa - HomePage
  bool isLoggedIn = false; // Login holati
  String fullName = "KundalikCOM Mobile";

  // Logout funksiyasini yaratish
  Future<void> _logOut() async {
    showLogoutConfirmationDialog(context); // Dialogni chaqirish
  }

  // Sahifalar ro'yxati
  final List<Widget> _pages = [
    const HomePage(),
    const DatasPage(),
    const LetsenziyaPage(),
  ];
  // DatabaseHelper orqali full_name ni olish
  Future<void> _loadFullName() async {
    final name =
        await DatabaseHelper().getData("full_name") ?? "KundalikCOM Mobile";
    setState(() {
      fullName = name; // Full name ni yangilash
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Ilova ochilganda tokenni tekshirish
    _loadFullName();
  }

  // Tokenni tekshirish
  Future<void> _checkLoginStatus() async {
    var token = await DatabaseHelper().getData('token'); // Tokenni olish
    if (token != null) {
      setState(() {
        isLoggedIn = true; // Agar token bo'lsa, foydalanuvchi tizimga kirgan
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 3 && !isLoggedIn) {
      // Agar login sahifasini bosilsa va foydalanuvchi kirgan bo'lmasa, login sahifasini ko'rsat
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(onLogin: _onLogin)),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onLogin() async {
    setState(() {
      isLoggedIn = true; // Login bo'lganda holatni yangilang
      _selectedIndex = 0; // HomePage'ga o'ting
      _loadFullName();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        leading: Icon(
          isLoggedIn ? Icons.account_circle : Icons.login, // Hisob ikonkasi
          color: const Color.fromARGB(255, 85, 0, 255),
        ),
        title: Text(
          fullName,
          style: const TextStyle(color: Color.fromARGB(255, 85, 0, 255)),
        ),
        backgroundColor: const Color.fromARGB(255, 214, 193, 255),
      ),
      body: isLoggedIn
          ? _pages[_selectedIndex]
          : LoginPage(
              onLogin:
                  _onLogin), // Agar login qilinmasa, login sahifasini ko'rsat
      bottomNavigationBar:
          isLoggedIn // Agar foydalanuvchi login qilgan bo'lsa, navigatsiya ko'rsatilsin
              ? BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Bosh sahifa',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.data_usage),
                      label: 'Ma\'lumotlar',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assignment_turned_in),
                      label: 'Letsenziya',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                )
              : null,
    );
  }
}
