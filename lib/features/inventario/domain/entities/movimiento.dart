class Movimiento {
  final String id;
  final String productoId;
  final String tipo; // 'entrada' | 'salida' | 'ajuste'
  final int cantidad;
  final int stockAnterior;
  final int stockResultante;
  final String? motivo;
  final String responsable;
  final DateTime fecha;

  Movimiento({
    required this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockResultante,
    this.motivo,
    required this.responsable,
    required this.fecha,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productoId': productoId,
        'tipo': tipo,
        'cantidad': cantidad,
        'stockAnterior': stockAnterior,
        'stockResultante': stockResultante,
        'motivo': motivo,
        'responsable': responsable,
        'fecha': fecha.toIso8601String(),
      };

  factory Movimiento.fromMap(Map<String, dynamic> m) => Movimiento(
        id: m['id'],
        productoId: m['productoId'],
        tipo: m['tipo'],
        cantidad: m['cantidad'],
        stockAnterior: m['stockAnterior'],
        stockResultante: m['stockResultante'],
        motivo: m['motivo'],
        responsable: m['responsable'],
        fecha: DateTime.parse(m['fecha']),
      );
}
