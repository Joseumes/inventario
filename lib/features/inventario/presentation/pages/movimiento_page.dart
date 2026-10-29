import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../productos/domain/entities/producto.dart';
import '../../../productos/presentation/providers/producto_provider.dart';
import '../providers/movimiento_provider.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../../../core/errors/mensajes.dart';
import '../../../../app/tema.dart';

/// PANTALLA: Registro de movimientos (entrada, salida y ajuste).
///
/// • Entrada/Salida: cantidad > 0 + motivo (con sugerencias rápidas).
/// • Ajuste: cantidad contada + justificación OBLIGATORIA.
/// • Los errores de reglas de negocio se muestran de forma legible
///   (p. ej. "Stock insuficiente: solicitas 5 y hay 4").
class MovimientoPage extends StatefulWidget {
  final String productoId;
  final String tipoInicial; // entrada | salida | ajuste
  final int? cantidadInicial;
  final String? motivoInicial;

  const MovimientoPage({
    super.key,
    required this.productoId,
    this.tipoInicial = 'entrada',
    this.cantidadInicial,
    this.motivoInicial,
  });

  @override
  State<MovimientoPage> createState() => _MovimientoPageState();
}

class _MovimientoPageState extends State<MovimientoPage> {
  late String _tipo;
  final _cantidad = TextEditingController();
  final _motivo = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Producto? _producto;
  bool _guardando = false;

  static const _motivosEntrada = ['Compra', 'Devolución', 'Reingreso'];
  static const _motivosSalida = ['Venta', 'Daño', 'Merma'];

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
    if (widget.cantidadInicial != null) {
      _cantidad.text = widget.cantidadInicial.toString();
    }
    if (widget.motivoInicial != null) {
      _motivo.text = widget.motivoInicial!;
    }
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    final p =
        await context.read<ProductoProvider>().obtenerPorId(widget.productoId);
    if (mounted) setState(() => _producto = p);
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final movProvider = context.read<MovimientoProvider>();
    final productoProvider = context.read<ProductoProvider>();
    final responsable = context.read<PerfilProvider>().nombre;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final cant = int.parse(_cantidad.text.trim());
      if (_tipo == 'entrada') {
        await movProvider.registrarEntrada(
          productoId: widget.productoId,
          cantidad: cant,
          motivo: _motivo.text.trim(),
          responsable: responsable,
        );
      } else if (_tipo == 'salida') {
        await movProvider.registrarSalida(
          productoId: widget.productoId,
          cantidad: cant,
          motivo: _motivo.text.trim(),
          responsable: responsable,
        );
      } else {
        await movProvider.registrarAjuste(
          productoId: widget.productoId,
          cantidadContada: cant,
          justificacion: _motivo.text.trim(),
          responsable: responsable,
        );
      }
      await productoProvider.cargarProductos();
      messenger.showSnackBar(SnackBar(
        content: Text('Movimiento registrado por $responsable'),
      ));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(mensajeAmigable(e)),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_producto == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _producto!;
    final esAjuste = _tipo == 'ajuste';

    return Scaffold(
      appBar: AppBar(title: Text('Movimiento: ${p.nombre}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- ESTADO ACTUAL ----------
            Card(
              color: p.stockBajo ? TemaApp.alerta.withValues(alpha: 0.10) : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stock actual',
                            style: TextStyle(color: Colors.black54)),
                        Text('${p.stockActual}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Stock mínimo',
                            style: TextStyle(color: Colors.black54)),
                        Text('${p.stockMinimo}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- TIPO ----------
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'entrada',
                    label: Text('Entrada'),
                    icon: Icon(Icons.add)),
                ButtonSegment(
                    value: 'salida',
                    label: Text('Salida'),
                    icon: Icon(Icons.remove)),
                ButtonSegment(
                    value: 'ajuste',
                    label: Text('Ajuste'),
                    icon: Icon(Icons.tune)),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 16),

            // ---------- CANTIDAD ----------
            TextFormField(
              controller: _cantidad,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: esAjuste ? 'Cantidad contada *' : 'Cantidad *',
                helperText: esAjuste
                    ? 'El stock pasará a ser esta cantidad'
                    : _tipo == 'entrada'
                        ? 'Unidades que ingresan al inventario'
                        : 'Unidades que salen del inventario',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null) return 'Ingresa una cantidad válida';
                if (esAjuste) {
                  if (n < 0) return 'No puede ser negativa';
                  if (n == p.stockActual) {
                    return 'El conteo es igual al stock actual: no hay nada que ajustar';
                  }
                } else if (n <= 0) {
                  return 'Debe ser mayor a cero';
                }
                if (_tipo == 'salida' && n > p.stockActual) {
                  return 'No hay stock suficiente: hay ${p.stockActual}';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ---------- MOTIVO / JUSTIFICACIÓN ----------
            TextFormField(
              controller: _motivo,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText:
                    esAjuste ? 'Justificación *' : 'Motivo *',
                hintText: esAjuste
                    ? 'Ej.: conteo físico mensual, faltante detectado...'
                    : _tipo == 'entrada'
                        ? 'Ej.: compra a proveedor, devolución...'
                        : 'Ej.: venta, producto dañado...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 8),
            // Sugerencias rápidas de motivo
            if (!esAjuste)
              Wrap(
                spacing: 6,
                children: (_tipo == 'entrada' ? _motivosEntrada : _motivosSalida)
                    .map((m) => ActionChip(
                          label: Text(m),
                          onPressed: () => _motivo.text = m,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 24),

            // ---------- GUARDAR ----------
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Registrar'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los movimientos confirmados no se pueden editar ni eliminar. '
              'Los errores se corrigen con un nuevo movimiento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
