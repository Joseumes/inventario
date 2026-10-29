import '../../../../core/storage/local_storage.dart';
import './../domain/repositories/perfil_repository.dart';

/// Implementación del repositorio de perfil sobre LocalStorage.
class PerfilRepositoryImpl implements PerfilRepository {
  final LocalStorage storage;

  PerfilRepositoryImpl(this.storage);

  @override
  Future<String> obtenerNombre() async => storage.getResponsable();

  @override
  Future<void> guardarNombre(String nombre) => storage.setResponsable(nombre);
}
