class Maquina {
  final int?   id;
  final String fuel;
  final String localizacao;
  final String modelo;
  final String marca;
  final String serie;
  final String criticidade;
  final String capacidade;

  Maquina({
    this.id,
    required this.fuel,
    required this.localizacao,
    required this.modelo,
    required this.marca,
    required this.serie,
    required this.criticidade,
    required this.capacidade,
  });

  factory Maquina.fromMap(Map<String, dynamic> map) {
    return Maquina(
      id         : map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      fuel       : map['fuel']?.toString()        ?? '',
      localizacao: map['localizacao']?.toString() ?? '',
      modelo     : map['modelo']?.toString()      ?? '',
      marca      : map['marca']?.toString()        ?? '',
      serie      : map['serie']?.toString()        ?? '',
      criticidade: map['criticidade']?.toString() ?? '',
      capacidade : map['capacidade']?.toString()  ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fuel'       : fuel,
      'localizacao': localizacao,
      'modelo'     : modelo,
      'marca'      : marca,
      'serie'      : serie,
      'criticidade': criticidade,
      'capacidade' : capacidade,
    };
  }
}