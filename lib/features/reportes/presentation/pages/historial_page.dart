import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../inventario/domain/entities/movimiento.dart';
import '../../../inventario/domain/entities/filtro_movimientos.dart';
import '../../../inventario/presentation/providers/movimiento_provider.dart';
import '../../../productos/presentation/providers/producto_provider.dart';
import '../../../../app/tema.dart';

/// PANTALLA: Historial y reportes.
///
/// • Historial de movimientos filtrado por producto, tipo y fechas.
/// • Resumen: productos activos, alertas y valor del inventario
///   (existencias × precio de compra, estimación sin métodos contables).
/// • Exportación a CSV del inventario y de los movimientos filtrados.
class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  String? _filtroTipo;
  String? _filtroProducto;
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovimientoProvider>().cargarMovimientos();
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  List<Movimiento> _aplicarFiltros(List<Movimiento> base) {
    return context.read<MovimientoProvider>().filtrar(FiltroMovimientos(
          tipo: _filtroTipo,
          productoId: _filtroProducto,
          desde: _desde,
          hasta: _hasta,
        ));
  }

  Future<void> _exportarCsv() async {
    final productos = context.read<ProductoProvider>().productosActivos;
    if (productos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay productos para exportar')));
      return;
    }
    final rows = <List<dynamic>>[
      [
        'Código',
        'Nombre',
        'Stock',
        'Stock Mínimo',
        'Precio Compra',
        'Precio Venta',
        'Valor Inventario'
      ],
    ];
    for (final p in productos) {
      rows.add([
        p.codigo,
        p.nombre,
        p.stockActual,
        p.stockMinimo,
        p.precioCompra,
        p.precioVenta,
        p.valorInventario,
      ]);
    }
    // Totales
    final total = productos.fold<double>(0, (s, p) => s + p.valorInventario);
    rows.add([]);
    rows.add(['', '', '', '', '', 'VALOR TOTAL', total]);

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/inventario.csv');
    await file.writeAsString(csv);
    if (!mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Inventario CSV');
  }

  Future<void> _exportarMovimientosCsv() async {
    final movs = _aplicarFiltros(context.read<MovimientoProvider>().movimientos);
    if (movs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay movimientos para exportar')));
      return;
    }
    final prods = context.read<ProductoProvider>().productos;
    String nombreDe(String id) {
      for (final p in prods) {
        if (p.id == id) return p.nombre;
      }
      return 'Producto eliminado';
    }

    final rows = <List<dynamic>>[
      [
        'Tipo',
        'Producto',
        'Cantidad',
        'Stock Anterior',
        'Stock Resultante',
        'Motivo',
        'Responsable',
        'Fecha'
      ],
    ];
    for (final m in movs) {
      rows.add([
        m.tipo,
        nombreDe(m.productoId),
        m.cantidad,
        m.stockAnterior,
        m.stockResultante,
        m.motivo ?? '',
        m.responsable,
        DateFormat('dd/MM/yyyy HH:mm').format(m.fecha),
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/movimientos.csv');
    await file.writeAsString(csv);
    if (!mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Movimientos CSV');
  }

  @override
  Widget build(BuildContext context) {
    final movProvider = context.watch<MovimientoProvider>();
    final prodProvider = context.watch<ProductoProvider>();
    final movimientos = _aplicarFiltros(movProvider.movimientos);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final dfmt = DateFormat('dd/MM/yy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial y reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar inventario CSV',
            onPressed: _exportarCsv,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar movimientos CSV',
            onPressed: movimientos.isEmpty ? null : _exportarMovimientosCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- RESUMEN ----------
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _resumenFila('Productos activos',
                      '${prodProvider.productosActivos.length}'),
                  _resumenFila('Alertas de stock bajo',
                      '${prodProvider.productosStockBajo.length}',
                      color: TemaApp.alerta),
                  _resumenFila('Valor del inventario',
                      'Q${prodProvider.valorInventario.toStringAsFixed(2)}',
                      color: TemaApp.entrada),
                ],
              ),
            ),
          ),
          // ---------- FILTROS ----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _filtroTipo,
                        hint: const Text('Tipo'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(
                              value: 'entrada', child: Text('Entrada')),
                          DropdownMenuItem(
                              value: 'salida', child: Text('Salida')),
                          DropdownMenuItem(
                              value: 'ajuste', child: Text('Ajuste')),
                        ],
                        onChanged: (v) => setState(() => _filtroTipo = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _filtroProducto,
                        hint: const Text('Producto'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Todos')),
                          ...prodProvider.productos.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (v) => setState(() => _filtroProducto = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                            _desde == null ? 'Desde' : dfmt.format(_desde!)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _desde ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _desde = d);
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                            _hasta == null ? 'Hasta' : dfmt.format(_hasta!)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _hasta ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _hasta = d);
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Limpiar filtros',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _filtroTipo = null;
                        _filtroProducto = null;
                        _desde = null;
                        _hasta = null;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ---------- LISTA ----------
          Expanded(
            child: movProvider.cargando
                ? const Center(child: CircularProgressIndicator())
                : movimientos.isEmpty
                    ? const Center(
                        child: Text('Sin movimientos con estos filtros'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: movimientos.length,
                        itemBuilder: (context, i) {
                          final m = movimientos[i];
                          final color = m.tipo == 'entrada'
                              ? TemaApp.entrada
                              : m.tipo == 'salida'
                                  ? TemaApp.salida
                                  : TemaApp.ajuste;
                          String nombre = 'Producto eliminado';
                          for (final p in prodProvider.productos) {
                            if (p.id == m.productoId) {
                              nombre = p.nombre;
                              break;
                            }
                          }
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(
                                  m.tipo == 'entrada'
                                      ? Icons.add
                                      : m.tipo == 'salida'
                                          ? Icons.remove
                                          : Icons.tune,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                  '${m.tipo.toUpperCase()} · ${m.cantidad} — $nombre'),
                              subtitle: Text(
                                '${fmt.format(m.fecha)}\n'
                                'Stock: ${m.stockAnterior} → ${m.stockResultante}\n'
                                'Motivo: ${m.motivo ?? "-"} · Resp.: ${m.responsable}',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _resumenFila(String label, String valor, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(valor,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
