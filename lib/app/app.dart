import 'package:flutter/material.dart';
import 'tema.dart';
import '../features/inicio/presentation/pages/inicio_page.dart';
import '../features/productos/presentation/pages/productos_page.dart';
import '../features/escaner/presentation/pages/escaner_page.dart';
import '../features/reportes/presentation/pages/historial_page.dart';

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.temaClaro,
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
  int _index = 0;

  void _setTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      InicioPage(onNavigateToTab: _setTab),
      const ProductosPage(),
      const EscanerPage(),
      const HistorialPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: _setTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: 'Productos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Escáner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}
