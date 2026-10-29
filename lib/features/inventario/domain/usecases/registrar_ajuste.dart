import '../../../../core/errors/failures.dart';
import '../../../productos/domain/repositories/producto_repository.dart';
import '../repositories/movimiento_repository.dart';
import '../services/reglas_inventario.dart';

/// CU-09: Registrar AJUSTE de inventario (conteo físico).
///
/// Reglas aplicadas (en el dominio):
/// • La cantidad contada no puede ser negativa.
/// • Debe existir diferencia con el stock actual.
/// • La justificación es OBLIGATORIA.
/// • La cantidad resultante pasa a ser la cantidad contada.
class RegistrarAjuste {
  final ProductoRepository productos;
  final MovimientoRepository movimientos;

  RegistrarAjuste(this.productos, this.movimientos);

  Future<void> call({
    required String productoId,
    required int cantidadContada,
    required String justificacion,
    required String responsable,
  }) async {
    if (cantidadContada < 0) {
      throw ValidacionFailure('La cantidad no puede ser negativa');
    }
    final justifLimpia =
        ReglasInventario.validarMotivo(justificacion, obligatorioJustificacion: true);

    final producto = await productos.obtenerPorId(productoId);
    if (producto == null) {
      throw ValidacionFailure('Producto no encontrado');
    }

    final anterior = producto.stockActual;
    if (anterior == cantidadContada) {
      throw ValidacionFailure(
          'No hay diferencia entre el conteo ($cantidadContada) y el stock actual');
    }

    await movimientos.registrarConActualizacionStock(
      movimiento: ReglasInventario.construirMovimiento(
        productoId: productoId,
        tipo: 'ajuste',
        cantidad: cantidadContada,
        stockAnterior: anterior,
        stockResultante: cantidadContada,
        motivo: justifLimpia,
        responsable: responsable,
      ),
      productoResultante: producto.copyWith(stockActual: cantidadContada),
    );
  }
}
