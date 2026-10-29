import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../productos/presentation/providers/producto_provider.dart';
import '../../../inventario/presentation/providers/movimiento_provider.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../../productos/presentation/pages/producto_form_page.dart';
import '../../../perfil/presentation/pages/perfil_page.dart';
import '../../../../app/tema.dart';

/// PANTALLA: Inicio (resumen, alertas y accesos rápidos).
class InicioPage extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  const InicioPage({super.key, this.onNavigateToTab});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<MovimientoProvider>().cargarMovimientos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prod = context.watch<ProductoProvider>();
    final mov = context.watch<MovimientoProvider>();
    final responsable = context.watch<PerfilProvider>().nombre;
    final nav = widget.onNavigateToTab;
    final productosDe = prod.productos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario Inteligente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mi perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilPage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await prod.cargarProductos();
          await mov.cargarMovimientos();
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ---------- SALUDO ----------
            Text('Hola, $responsable',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Resumen de tu inventario',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),

            // ---------- MÉTRICAS ----------
            Row(
              children: [
                _metrica('Productos', '${prod.productosActivos.length}',
                    Icons.inventory_2, TemaApp.primario),
                const SizedBox(width: 8),
                _metrica('Stock bajo', '${prod.productosStockBajo.length}',
                    Icons.warning_amber, TemaApp.alerta),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metrica('Movimientos', '${mov.movimientos.length}',
                    Icons.swap_vert, TemaApp.ajuste),
                const SizedBox(width: 8),
                _metrica('Valor', 'Q${prod.valorInventario.toStringAsFixed(0)}',
                    Icons.attach_money, TemaApp.entrada),
              ],
            ),
            const SizedBox(height: 20),

            // ---------- ACCESOS RÁPIDOS ----------
            const Text('Accesos rápidos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.7,
              children: [
                _acceso('Nuevo producto', Icons.add_box, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductoFormPage()),
                  );
                  if (mounted) {
                    context.read<ProductoProvider>().cargarProductos();
                  }
                }),
                _acceso('Ver productos', Icons.list, () {
                  nav?.call(1);
                }),
                _acceso('Escanear', Icons.qr_code_scanner, () {
                  nav?.call(2);
                }),
                _acceso('Historial', Icons.history, () {
                  nav?.call(3);
                }),
              ],
            ),
            const SizedBox(height: 20),

            // ---------- ALERTAS ----------
            if (prod.productosStockBajo.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: TemaApp.alerta, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'Alertas de stock bajo (${prod.productosStockBajo.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...prod.productosStockBajo.take(5).map((p) => Card(
                    color: TemaApp.alerta.withValues(alpha: 0.08),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber,
                          color: TemaApp.alerta),
                      title: Text(p.nombre),
                      subtitle: Text(
                          'Stock: ${p.stockActual} · Mínimo: ${p.stockMinimo}'),
                      trailing: Text(p.codigo,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // ---------- ÚLTIMOS MOVIMIENTOS ----------
            const Text('Últimos movimientos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (mov.movimientos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.history, color: Colors.grey),
                      SizedBox(height: 6),
                      Text('Sin movimientos aún',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ...mov.movimientos.take(5).map((m) {
                final color = m.tipo == 'entrada'
                    ? TemaApp.entrada
                    : m.tipo == 'salida'
                        ? TemaApp.salida
                        : TemaApp.ajuste;
                String nombre = 'Producto eliminado';
                for (final p in productosDe) {
                  if (p.id == m.productoId) {
                    nombre = p.nombre;
                    break;
                  }
                }
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      m.tipo == 'entrada'
                          ? Icons.add_circle
                          : m.tipo == 'salida'
                              ? Icons.remove_circle
                              : Icons.tune,
                      color: color,
                    ),
                    title: Text(
                        '$nombre · ${m.tipo.toUpperCase()} ${m.cantidad}'),
                    subtitle: Text(
                        'Stock: ${m.stockAnterior} → ${m.stockResultante}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _metrica(String label, String valor, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(valor,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: color)),
              Text(label,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acceso(String label, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: TemaApp.primario),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
