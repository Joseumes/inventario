import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/entities/producto.dart';
import '../../../../app/tema.dart';

/// Tarjeta de producto para el listado.
/// Muestra foto (si existe), código, categoría y estado de stock.
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  const ProductoCard(
      {super.key, required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final desactivado = !p.activo;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Foto o ícono
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: Colors.grey.shade200,
                  child: (p.fotoBase64 != null && p.fotoBase64!.isNotEmpty)
                      ? Image.memory(
                          base64Decode(p.fotoBase64!),
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.inventory_2,
                          color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(width: 12),
              // Datos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(p.codigo,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(
                          p.stockBajo && !desactivado
                              ? 'Stock: ${p.stockActual} (bajo)'
                              : 'Stock: ${p.stockActual}',
                          color: desactivado
                              ? Colors.grey
                              : p.stockBajo
                                  ? TemaApp.alerta
                                  : TemaApp.entrada,
                          icon: desactivado
                              ? Icons.block
                              : p.stockBajo
                                  ? Icons.warning_amber
                                  : Icons.check_circle_outline,
                        ),
                        if (desactivado)
                          const _EstadoChip(
                              texto: 'Desactivado', color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              // Precio
              Text(
                'Q${p.precioVenta.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String texto, {required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(texto,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String texto;
  final Color color;
  const _EstadoChip({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
