import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/producto_provider.dart';
import '../widgets/producto_card.dart';
import 'producto_form_page.dart';
import 'producto_detalle_page.dart';
import '../../../../app/tema.dart';

/// PANTALLA: Productos (listado, búsqueda y filtros).
///
/// • Búsqueda por nombre, código o descripción.
/// • Filtros rápidos: Todos / Stock bajo / Inactivos.
/// • Estados de carga, vacío y alerta de stock bajo.
class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _searchController = TextEditingController();
  bool _soloStockBajo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();

    // Aplica el filtro de stock bajo sobre el listado del provider.
    final lista = _soloStockBajo
        ? provider.productosFiltrados.where((p) => p.stockBajo).toList()
        : provider.productosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => provider.cargarProductos(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o descripción...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setFiltro('');
                        },
                      ),
              ),
              onChanged: provider.setFiltro,
            ),
          ),
          // Filtros rápidos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                      'Stock bajo (${provider.productosStockBajo.length})'),
                  selected: _soloStockBajo,
                  selectedColor: TemaApp.alerta.withValues(alpha: 0.2),
                  checkmarkColor: TemaApp.alerta,
                  onSelected: (v) => setState(() => _soloStockBajo = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Mostrar inactivos'),
                  selected: provider.verInactivos,
                  onSelected: (_) => provider.alternarInactivos(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? _EstadoVacio(
                        icono: Icons.cloud_off,
                        titulo: 'Error al cargar',
                        mensaje: provider.error!,
                      )
                    : lista.isEmpty
                        ? _EstadoVacio(
                            icono: Icons.inventory_2_outlined,
                            titulo: _soloStockBajo
                                ? 'Sin alertas de stock'
                                : 'Sin productos',
                            mensaje: _soloStockBajo
                                ? 'Ningún producto está por debajo de su stock mínimo.'
                                : 'Presiona "Nuevo" para registrar el primer producto.',
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.cargarProductos(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: lista.length,
                              itemBuilder: (context, i) {
                                final p = lista[i];
                                return ProductoCard(
                                  producto: p,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductoDetallePage(productoId: p.id),
                                    ),
                                  ).then((_) => provider.cargarProductos()),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductoFormPage()),
          );
          provider.cargarProductos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}

/// Estado vacío reutilizable (requisito: estados vacíos claros).
class _EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  const _EstadoVacio(
      {required this.icono, required this.titulo, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(titulo,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
