/// Contrato del repositorio de perfil (capa de dominio).
abstract class PerfilRepository {
  Future<String> obtenerNombre();
  Future<void> guardarNombre(String nombre);
}
