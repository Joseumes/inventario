import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ETIQUETA del producto: nombre + código + código de barras Code 128
/// + código QR. El contenido escaneado es SOLO el código único del
/// producto; las existencias se consultan en la base de datos y NO se
/// guardan dentro del QR (cambian con cada movimiento).
///
/// Envolver esta vista en un [RepaintBoundary] con GlobalKey permite
/// capturarla como PNG para compartir/imprimir (ver detalle del producto).
class EtiquetaWidget extends StatelessWidget {
  final String nombre;
  final String codigo;
  const EtiquetaWidget(
      {super.key, required this.nombre, required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: codigo,
            width: 220,
            height: 60,
            drawText: true,
          ),
          const SizedBox(height: 10),
          QrImageView(data: codigo, size: 120),
          const SizedBox(height: 6),
          Text(codigo,
              style: const TextStyle(
                  letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
