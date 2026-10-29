import '../../../../core/errors/failures.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../productos/domain/entities/producto.dart';
import '../entities/movimiento.dart';

/// SERVICIO DE DOMINIO: reglas de inventario centralizadas.
///
/// Aquí viven las reglas de negocio de los movimientos para que NO
/// dependan de los widgets ni de la base de datos (requisito del
/// enunciado). Los casos de uso y los tests las reutilizan.
class ReglasInventario {
  ReglasInventario._();

  /// La cantidad de entrada/salida debe ser mayor que cero.
  static void validarCantidadPositiva(int cantidad) {
    if (cantidad <= 0) {
      throw ValidacionFailure('La cantidad debe ser mayor a cero');
    }
  }

  /// No se permiten salidas superiores al stock disponible.
  static void validarStockSuficiente(int solicitado, int disponible) {
    if (solicitado > disponible) {
      throw StockInsuficienteFailure(
          'Stock insuficiente: solicitas $solicitado y hay $disponible');
    }
  }

  /// Los productos desactivados no admiten movimientos.
  static void validarProductoActivo(Producto producto) {
    if (!producto.activo) {
      throw ValidacionFailure(
          'El producto está desactivado y no admite movimientos');
    }
  }

  /// Entrada y salida exigen motivo; el ajuste exige justificación.
  static String validarMotivo(String motivo, {bool obligatorioJustificacion = false}) {
    final m = motivo.trim();
    if (m.isEmpty) {
      throw ValidacionFailure(obligatorioJustificacion
          ? 'La justificación del ajuste es obligatoria'
          : 'El motivo del movimiento es obligatorio');
    }
    return m;
  }

  /// Crea una entidad Movimiento con id y fecha actuales.
  static Movimiento construirMovimiento({
    required String productoId,
    required String tipo,
    required int cantidad,
    required int stockAnterior,
    required int stockResultante,
    required String motivo,
    required String responsable,
  }) {
    return Movimiento(
      id: IdGenerator.nuevoId(),
      productoId: productoId,
      tipo: tipo,
      cantidad: cantidad,
      stockAnterior: stockAnterior,
      stockResultante: stockResultante,
      motivo: motivo,
      responsable: responsable,
      fecha: DateTime.now(),
    );
  }
}
