import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/producto.dart';
import '../providers/producto_provider.dart';
import '../widgets/etiqueta_widget.dart';
import 'producto_form_page.dart';
import '../../../inventario/presentation/pages/movimiento_page.dart';
import '../../../inventario/domain/entities/movimiento.dart';
import '../../../inventario/presentation/providers/movimiento_provider.dart';
import '../../../../app/tema.dart';

/// PANTALLA: Detalle del producto.
///
/// • Datos y existencias actuales.
/// • Acciones de entrada / salida / ajuste.
/// • Etiqueta con código de barras Code 128 y QR, compartible/exportable
///   como imagen PNG para impresión.
/// • Historial reciente del producto.
/// • Desactivar (o eliminar si no tiene movimientos) y reactivar.
class ProductoDetallePage extends StatefulWidget {
  final String productoId;
  const ProductoDetallePage({super.key, required this.productoId});

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  Producto? _producto;
  List<Movimiento> _movimientos = [];
  final _etiquetaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final movProvider = context.read<MovimientoProvider>();
    final prodProvider = context.read<ProductoProvider>();
    final p = await prodProvider.obtenerPorId(widget.productoId);
    // Historial del producto (lista completa ya cargada en el provider).
    final movs = movProvider.movimientosDe(widget.productoId);
    if (!mounted) return;
    setState(() {
      _producto = p;
      _movimientos = movs;
    });
  }

  /// Exporta la etiqueta (Code 128 + QR) como imagen PNG para
  /// compartir o imprimir. Se captura el widget con RepaintBoundary.
  Future<void> _compartirEtiqueta(Producto p) async {
    try {
      final boundary = _etiquetaKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (!mounted) return;
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'image/png', name: 'etiqueta_${p.codigo}.png')
        ],
        text: 'Etiqueta de ${p.nombre} (${p.codigo})',
        subject: 'Etiqueta ${p.codigo}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'No se pudo generar la imagen de la etiqueta en este dispositivo.'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_producto == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _producto!;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductoFormPage(productoEditar: p)),
              );
              _cargar();
            },
          ),
          IconButton(
            icon: Icon(p.activo ? Icons.delete_outline : Icons.restart_alt),
            tooltip: p.activo ? 'Desactivar' : 'Reactivar',
            onPressed: () =>
                p.activo ? _confirmarDesactivar(p) : _confirmarReactivar(p),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- FOTO ----------
          if (p.fotoBase64 != null && p.fotoBase64!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(p.fotoBase64!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),

          // ---------- DATOS ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.nombre,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      if (!p.activo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Desactivado',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  _fila('Código', p.codigo),
                  _fila('Descripción', p.descripcion ?? '—'),
                  _fila('Stock actual', '${p.stockActual}',
                      destacado: true),
                  _fila('Stock mínimo', '${p.stockMinimo}'),
                  _fila('Precio compra',
                      'Q${p.precioCompra.toStringAsFixed(2)}'),
                  _fila(
                      'Precio venta', 'Q${p.precioVenta.toStringAsFixed(2)}'),
                  _fila('Valor inventario',
                      'Q${p.valorInventario.toStringAsFixed(2)}'),
                  if (p.stockBajo && p.activo)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TemaApp.alerta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: TemaApp.alerta),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stock bajo: hay ${p.stockActual} y el mínimo es ${p.stockMinimo}',
                              style:
                                  const TextStyle(color: TemaApp.alerta),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ---------- ACCIONES ----------
          if (p.activo)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _irMovimiento(p, 'entrada'),
                    style: FilledButton.styleFrom(
                        backgroundColor: TemaApp.entrada),
                    icon: const Icon(Icons.add),
                    label: const Text('Entrada'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _irMovimiento(p, 'salida'),
                    style: FilledButton.styleFrom(
                        backgroundColor: TemaApp.salida),
                    icon: const Icon(Icons.remove),
                    label: const Text('Salida'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _irMovimiento(p, 'ajuste'),
                    style: FilledButton.styleFrom(
                        backgroundColor: TemaApp.ajuste),
                    icon: const Icon(Icons.tune),
                    label: const Text('Ajuste'),
                  ),
                ),
              ],
            )
          else
            Card(
              color: Colors.grey.shade100,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                    'Producto desactivado: no admite movimientos. '
                    'Reactívalo para operar con él.',
                    textAlign: TextAlign.center),
              ),
            ),
          const SizedBox(height: 16),

          // ---------- ETIQUETAS ----------
          const Text('Etiquetas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Capturable para exportar como PNG
                  RepaintBoundary(
                    key: _etiquetaKey,
                    child: EtiquetaWidget(nombre: p.nombre, codigo: p.codigo),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _compartirEtiqueta(p),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Compartir PNG'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Share.share(
                            'Producto: ${p.nombre}\nCódigo: ${p.codigo}\n'
                            'Precio venta: Q${p.precioVenta.toStringAsFixed(2)}',
                            subject: 'Etiqueta ${p.nombre}',
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text('Compartir texto'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---------- HISTORIAL DEL PRODUCTO ----------
          const Text('Últimos movimientos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_movimientos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.history, color: Colors.grey),
                    SizedBox(height: 6),
                    Text('Sin movimientos registrados',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ..._movimientos.take(5).map((m) {
              final color = m.tipo == 'entrada'
                  ? TemaApp.entrada
                  : m.tipo == 'salida'
                      ? TemaApp.salida
                      : TemaApp.ajuste;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
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
                  title: Text('${m.tipo.toUpperCase()} · ${m.cantidad}'),
                  subtitle: Text(
                      'Stock: ${m.stockAnterior} → ${m.stockResultante}\nMotivo: ${m.motivo ?? "-"}'),
                  isThreeLine: true,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _fila(String label, String valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Flexible(
            child: Text(valor,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight:
                        destacado ? FontWeight.bold : FontWeight.w600,
                    fontSize: destacado ? 17 : 14,
                    color: destacado
                        ? Theme.of(context).colorScheme.primary
                        : null)),
          ),
        ],
      ),
    );
  }

  Future<void> _irMovimiento(Producto p, String tipo) async {
    final prodProvider = context.read<ProductoProvider>();
    final movProvider = context.read<MovimientoProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovimientoPage(productoId: p.id, tipoInicial: tipo),
      ),
    );
    if (!mounted) return;
    await prodProvider.cargarProductos();
    await movProvider.cargarMovimientos();
    _cargar();
  }

  Future<void> _confirmarDesactivar(Producto p) async {
    final provider = context.read<ProductoProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Desactivar producto'),
        content: const Text(
            'Si el producto tiene movimientos se desactivará y conservará '
            'su historial. Si no tiene, se eliminará. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Sí, desactivar')),
        ],
      ),
    );
    if (ok == true) {
      await provider.desactivarProducto(p.id);
      if (!mounted) return;
      navigator.pop();
    }
  }

  Future<void> _confirmarReactivar(Producto p) async {
    final provider = context.read<ProductoProvider>();
    await provider.reactivarProducto(p.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto reactivado')));
    _cargar();
  }
}
