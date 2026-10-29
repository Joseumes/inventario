import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../productos/presentation/providers/producto_provider.dart';
import '../../../productos/presentation/pages/producto_detalle_page.dart';
import '../../../productos/presentation/pages/producto_form_page.dart';
import '../../../productos/domain/entities/producto.dart';

/// PANTALLA: Escáner de códigos de barras y QR.
///
/// • Lee Code 128 (barras) y QR con la cámara del dispositivo.
/// • Maneja errores de cámara y permisos con mensajes claros.
/// • Si el código no está registrado, ofrece crear el producto con el
///   código ya prellenado.
/// • Búsqueda manual por código o nombre cuando no hay cámara.
class EscanerPage extends StatefulWidget {
  const EscanerPage({super.key});

  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage> {
  MobileScannerController? _controller;
  final _manualCtrl = TextEditingController();
  bool _procesando = false;
  bool _camaraActiva = false;
  String? _errorCamara;

  @override
  void initState() {
    super.initState();
    _prepararCamara();
  }

  Future<void> _prepararCamara() async {
    if (kIsWeb) {
      setState(() => _errorCamara =
          'La cámara no está disponible en esta plataforma.\nUsa la búsqueda manual.');
      return;
    }
    // Permiso de cámara (manejo explícito de permisos).
    final estado = await Permission.camera.request();
    if (estado.isDenied || estado.isPermanentlyDenied) {
      if (!mounted) return;
      setState(() => _errorCamara = estado.isPermanentlyDenied
          ? 'El permiso de cámara fue denegado permanentemente.\n'
              'Actívalo en Ajustes del dispositivo para poder escanear.'
          : 'Se necesita el permiso de cámara para escanear.\n'
              'También puedes usar la búsqueda manual.');
      return;
    }
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
      setState(() => _camaraActiva = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorCamara =
          'No se pudo iniciar la cámara en este dispositivo.\nUsa la búsqueda manual.');
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;
    final codigos = capture.barcodes;
    final raw = codigos.isEmpty ? null : codigos.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _procesando = true;
    try {
      await _controller?.stop();
    } catch (_) {}
    await _buscarYMostrar(raw);
  }

  Future<void> _buscarYMostrar(String codigo) async {
    final provider = context.read<ProductoProvider>();
    final navigator = Navigator.of(context);

    final producto = await provider.buscarPorCodigo(codigo);
    if (!mounted) {
      _procesando = false;
      return;
    }

    if (producto == null) {
      // Mensaje requerido: código no registrado → ofrecer crear.
      final crear = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          icon: const Icon(Icons.search_off, size: 40),
          title: const Text('Producto no registrado'),
          content: Text(
              'El código "$codigo" no existe en el inventario.\n'
              '¿Deseas crear un producto con este código?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cerrar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Crear producto')),
          ],
        ),
      );
      if (crear == true && mounted) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                ProductoFormPage(codigoInicial: codigo), // código prellenado
          ),
        );
        await provider.cargarProductos();
      }
    } else {
      if (!producto.activo && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('El producto está desactivado'),
          backgroundColor: Colors.orange,
        ));
      }
      await navigator.push(
        MaterialPageRoute(
            builder: (_) => ProductoDetallePage(productoId: producto.id)),
      );
      await provider.cargarProductos();
    }

    if (mounted) {
      try {
        await _controller?.start();
      } catch (_) {}
    }
    _procesando = false;
  }

  Future<void> _buscarPorNombre(String txt) async {
    if (txt.isEmpty) return;
    final provider = context.read<ProductoProvider>();
    final q = txt.toLowerCase();
    final resultados = provider.productos
        .where((p) =>
            p.activo &&
            (p.nombre.toLowerCase().contains(q) ||
                p.codigo.toLowerCase().contains(q)))
        .toList();
    if (!mounted) return;
    if (resultados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sin resultados para "$txt"'),
      ));
      return;
    }
    if (resultados.length == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ProductoDetallePage(productoId: resultados.first.id)),
      );
      return;
    }
    if (!mounted) return;
    final elegido = await showDialog<Producto>(
      context: context,
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('Selecciona un producto'),
        children: resultados
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogCtx, p),
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: Text(p.nombre),
                    subtitle: Text(p.codigo),
                  ),
                ))
            .toList(),
      ),
    );
    if (elegido != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductoDetallePage(productoId: elegido.id)),
      );
    }
  }

  Future<void> _ejecutarBusquedaManual() async {
    final txt = _manualCtrl.text.trim();
    if (txt.isEmpty) return;
    final provider = context.read<ProductoProvider>();
    final prod = await provider.buscarPorCodigo(txt);
    if (!mounted) return;
    if (prod != null) {
      await _buscarYMostrar(txt);
    } else {
      await _buscarPorNombre(txt);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner'),
        actions: [
          if (_camaraActiva)
            IconButton(
              icon: const Icon(Icons.flash_on),
              tooltip: 'Linterna',
              onPressed: () => _controller?.toggleTorch(),
            ),
          if (_camaraActiva)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              tooltip: 'Cambiar cámara',
              onPressed: () => _controller?.switchCamera(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _camaraActiva && _controller != null
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: _controller!,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.no_photography,
                                    size: 60, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  'Cámara no disponible\n${error.errorCode.name}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Marco guía
                      Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white70, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Text(
                          'Apunta al código de barras o QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : _errorCamara != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.no_photography,
                                  size: 60, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _errorCamara!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Búsqueda manual',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _manualCtrl,
                    decoration: InputDecoration(
                      hintText: 'Código o nombre...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _ejecutarBusquedaManual,
                      ),
                    ),
                    onSubmitted: (_) => _ejecutarBusquedaManual(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa el código para buscarlo directamente, o el nombre '
                    'para buscar coincidencias.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
