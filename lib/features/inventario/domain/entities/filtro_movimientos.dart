/// Filtros para la consulta de movimientos (capa de dominio).
class FiltroMovimientos {
  final String? productoId;
  final String? tipo; // entrada | salida | ajuste
  final DateTime? desde;
  final DateTime? hasta;

  const FiltroMovimientos({this.productoId, this.tipo, this.desde, this.hasta});

  bool get estaVacio =>
      productoId == null && tipo == null && desde == null && hasta == null;
}
