class Perfil {
  final String nombre;
  const Perfil({required this.nombre});

  Perfil copyWith({String? nombre}) => Perfil(nombre: nombre ?? this.nombre);
}
