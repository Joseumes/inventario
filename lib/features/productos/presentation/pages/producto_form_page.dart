import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/producto.dart';
import '../providers/producto_provider.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../../../core/errors/mensajes.dart';

/// PANTALLA: Formulario de producto (creación y edición).
///
/// Validaciones de formulario + reglas del dominio (código único,
/// precios no negativos, etc.). El stock inicial se registra
/// automáticamente como movimiento de ENTRADA (CU-05).
class ProductoFormPage extends StatefulWidget {
  final Producto? productoEditar;
  final String? codigoInicial; // Prefill al crear desde el escáner

  const ProductoFormPage({super.key, this.productoEditar, this.codigoInicial});

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precioCompra;
  late final TextEditingController _precioVenta;
  late final TextEditingController _stockMinimo;
  late final TextEditingController _stockInicial;
  String? _categoriaId;
  String? _fotoBase64;
  bool _guardando = false;

  bool get _esEdicion => widget.productoEditar != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productoEditar;
    _codigo =
        TextEditingController(text: p?.codigo ?? widget.codigoInicial ?? '');
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _precioCompra =
        TextEditingController(text: p?.precioCompra.toString() ?? '');
    _precioVenta = TextEditingController(text: p?.precioVenta.toString() ?? '');
    _stockMinimo = TextEditingController(text: p?.stockMinimo.toString() ?? '');
    _stockInicial = TextEditingController(text: '0');
    _categoriaId = p?.categoriaId;
    _fotoBase64 = p?.fotoBase64;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    _precioCompra.dispose();
    _precioVenta.dispose();
    _stockMinimo.dispose();
    _stockInicial.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
          source: ImageSource.camera, maxWidth: 600, imageQuality: 50);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _fotoBase64 = base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'No se pudo abrir la cámara. Verifica el permiso o usa la galería.'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  Future<void> _elegirGaleria() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 600, imageQuality: 50);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _fotoBase64 = base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No se pudo abrir la galería.'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final provider = context.read<ProductoProvider>();
    final responsable = context.read<PerfilProvider>().nombre;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final producto = Producto(
      id: widget.productoEditar?.id ?? const Uuid().v4(),
      codigo: _codigo.text.trim(),
      nombre: _nombre.text.trim(),
      descripcion:
          _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      categoriaId: _categoriaId,
      precioCompra:
          double.tryParse(_precioCompra.text.replaceAll(',', '.')) ?? 0,
      precioVenta: double.tryParse(_precioVenta.text.replaceAll(',', '.')) ?? 0,
      stockActual: _esEdicion ? widget.productoEditar!.stockActual : 0,
      stockMinimo: int.tryParse(_stockMinimo.text) ?? 0,
      fotoBase64: _fotoBase64,
    );

    try {
      if (_esEdicion) {
        await provider.actualizarProducto(producto);
        messenger.showSnackBar(
            const SnackBar(content: Text('Producto actualizado')));
      } else {
        // CU-01: crear producto.
        final creado = await provider.crearProducto(producto);

        // CU-05: existencias iniciales como movimiento de ENTRADA.
        final inicial = int.tryParse(_stockInicial.text) ?? 0;
        if (inicial > 0) {
          await provider.registrarStockInicial(
            productoId: creado.id,
            cantidad: inicial,
            responsable: responsable,
          );
          messenger.showSnackBar(SnackBar(
              content: Text(
                  'Producto creado con entrada inicial de $inicial unidades')));
        } else {
          messenger
              .showSnackBar(const SnackBar(content: Text('Producto creado')));
        }
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(mensajeAmigable(e)),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Abre un diálogo para crear una categoría que no exista y la selecciona.
  Future<void> _crearCategoria() async {
    final nombreCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: nombreCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogCtx, nombreCtrl.text.trim().isNotEmpty),
              child: const Text('Crear')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final nombre = nombreCtrl.text.trim();
    final provider = context.read<ProductoProvider>();
    await provider.crearCategoria(nombre);
    if (!mounted) return;
    // Seleccionar la categoría recién creada (o la existente si ya había una igual).
    final creada = provider.categorias
        .where(
          (c) => c.nombre.toLowerCase() == nombre.toLowerCase(),
        )
        .firstOrNull;
    if (creada != null) {
      setState(() => _categoriaId = creada.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<ProductoProvider>().categorias;

    return Scaffold(
      appBar: AppBar(
          title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- FOTO (opcional) ----------
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _fotoBase64 != null
                        ? MemoryImage(base64Decode(_fotoBase64!))
                        : null,
                    child: _fotoBase64 == null
                        ? const Icon(Icons.inventory,
                            size: 40, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: PopupMenuButton<String>(
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                      onSelected: (v) {
                        if (v == 'camara') _tomarFoto();
                        if (v == 'galeria') _elegirGaleria();
                        if (v == 'borrar') setState(() => _fotoBase64 = null);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'camara', child: Text('Cámara')),
                        PopupMenuItem(value: 'galeria', child: Text('Galería')),
                        PopupMenuItem(
                            value: 'borrar', child: Text('Quitar foto')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigo,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código único *',
                helperText:
                    'Identificador escaneable (se genera en Code 128 y QR)',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcion,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_categoriaId),
              initialValue: _categoriaId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                ...categorias.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nombre),
                  ),
                ),
                const DropdownMenuItem(
                  value: '__nueva_categoria__',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 6),
                      Text('Crear nueva categoría'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) async {
                if (v == '__nueva_categoria__') {
                  await _crearCategoria();
                } else {
                  setState(() => _categoriaId = v);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioCompra,
                    decoration: const InputDecoration(
                        labelText: 'Precio compra', prefixText: 'Q '),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (n == null) return 'Inválido';
                      if (n < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precioVenta,
                    decoration: const InputDecoration(
                        labelText: 'Precio venta', prefixText: 'Q '),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (n == null) return 'Inválido';
                      if (n < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockMinimo,
              decoration: const InputDecoration(
                labelText: 'Stock mínimo *',
                helperText: 'Se genera alerta cuando stock ≤ mínimo',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 0) ? 'Inválido' : null;
              },
            ),
            if (!_esEdicion) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockInicial,
                decoration: const InputDecoration(
                  labelText: 'Existencias iniciales',
                  helperText:
                      'Se registran como movimiento de ENTRADA (trazabilidad)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '0');
                  return (n == null || n < 0) ? 'Inválido' : null;
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
