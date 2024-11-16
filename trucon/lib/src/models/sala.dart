class Sala{
  final int id;
  final String dono;
  final DateTime? criacao;
  final String? password;
  final List<String> jogadores;

  Sala({
    required this.id,
    required this.dono,
    this.criacao,
    this.password,
    required this.jogadores,
  });

  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      id: json['id'] as int,
      dono: json['dono'] as String,
      criacao: json['criacao'] != null ? DateTime.parse(json['criacao'] as String) : null,
      password: json['senha'] as String?,
      jogadores: (json['jogador_set'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  void addJogador(String jogador) {
    jogadores.add(jogador);
  }

  int get quantidadeJogadores => jogadores.length;

  String get nomeSalas => 'Sala de $dono';
}