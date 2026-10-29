class Producto {
  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? categoriaId;
  final double precioCompra;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  final String? fotoBase64; // 👈 NUEVO: imagen comprimida en base64
  final bool activo;

  Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    required this.precioCompra,
    required this.precioVenta,
    required this.stockActual,
    required this.stockMinimo,
    this.fotoBase64,
    this.activo = true,
  });

  bool get stockBajo => stockActual <= stockMinimo;
  double get valorInventario => stockActual * precioCompra;

  Producto copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    String? categoriaId,
    double? precioCompra,
    double? precioVenta,
    int? stockActual,
    int? stockMinimo,
    String? fotoBase64,
    bool? activo,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoriaId: categoriaId ?? this.categoriaId,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
      activo: activo ?? this.activo,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'categoriaId': categoriaId,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        'stockActual': stockActual,
        'stockMinimo': stockMinimo,
        'fotoBase64': fotoBase64,
        'activo': activo,
      };

  factory Producto.fromMap(Map<String, dynamic> m) => Producto(
        id: m['id'] as String,
        codigo: m['codigo'] as String,
        nombre: m['nombre'] as String,
        descripcion: m['descripcion'] as String?,
        categoriaId: m['categoriaId'] as String?,
        precioCompra: (m['precioCompra'] as num).toDouble(),
        precioVenta: (m['precioVenta'] as num).toDouble(),
        stockActual: m['stockActual'] as int,
        stockMinimo: m['stockMinimo'] as int,
        fotoBase64: m['fotoBase64'] as String?,
        activo: m['activo'] as bool? ?? true,
      );
}
