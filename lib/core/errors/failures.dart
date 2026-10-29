class Failure {
  final String mensaje;
  Failure(this.mensaje);
}

class ValidacionFailure extends Failure {
  ValidacionFailure(super.mensaje);
}

class StockInsuficienteFailure extends Failure {
  StockInsuficienteFailure(super.mensaje);
}

class CodigoDuplicadoFailure extends Failure {
  CodigoDuplicadoFailure(super.mensaje);
}

class AlmacenamientoFailure extends Failure {
  AlmacenamientoFailure(super.mensaje);
}
