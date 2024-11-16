

class Jogador{
  int id;
  String username;
  int vitorias;
  int derrotas;
  int? salaId;

  Jogador({
    required this.id,
    required this.username,
    required this.vitorias,
    required this.derrotas,
    this.salaId,
  });

  factory Jogador.fromJson(Map<String, dynamic> json) {
    return Jogador(
      id: json['id'] as int,
      username: json['usuario'] as String,
      vitorias: json['vitorias'] as int,
      derrotas: json['derrotas'] as int,
      salaId: json['sala'] as int?,
    );
  }
}