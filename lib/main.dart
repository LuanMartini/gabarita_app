import 'package:flutter/material.dart';

void main() {
  runApp(const GabaritaApp());
}

class GabaritaApp extends StatelessWidget {
  const GabaritaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gabarita',
      debugShowCheckedModeBanner: false,
      // Aplicando o tema absolute black minimalista
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white54,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de telas provisórias para o professor ver a navegação
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreenProvisoria(),
    Center(child: Text('Questões', style: TextStyle(fontSize: 24))),
    Center(child: Text('Simulados', style: TextStyle(fontSize: 24))),
    Center(child: Text('Estatísticas', style: TextStyle(fontSize: 24))),
    Center(child: Text('Perfil', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Questões'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Simulados'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreenProvisoria extends StatelessWidget {
  const HomeScreenProvisoria({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bom dia, Lucas! 👋',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Você está com 5 dias de sequência 🔥',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: const Text('LM', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔥 5 dias de sequência!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                const Text('Continue estudando hoje para manter!'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Estudar'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}