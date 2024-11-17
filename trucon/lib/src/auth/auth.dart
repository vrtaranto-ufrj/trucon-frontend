import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sala.dart';
import '../models/jogador.dart';

class Conexao {
  static const String url = 'http://127.0.0.1:8000/api/';

  late String accessToken;
  late String refreshToken;

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${url}token/'),
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      accessToken = data['access'];
      refreshToken = data['refresh'];
    } else {
      throw Exception('Falha ao logar');
    }
  }

  Future<void> refreshAccessToken() async {
    final response = await http.post(
      Uri.parse('${url}token/refresh/'),
      body: {
        'refresh': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      accessToken = data['access'];
    } else {
      throw Exception('Falha ao atualizar token');
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('${url}cadastrar/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final errors = data['error'] ?? 'Erro desconhecido'; // Lida com erros de forma mais segura
      throw Exception('Falha ao cadastrar: $errors');
    }
  }

  Future<List<Sala>?> getSalas() async {
    final response = await http.get(
      Uri.parse('${url}salas/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      }
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => Sala.fromJson(e as Map<String, dynamic>)).toList();
    }

    final dataErro = jsonDecode(response.body);

    if (response.statusCode == 401 && dataErro['code'] == 'token_not_valid') {
      refreshAccessToken();
      return getSalas();
    }

    return null;
  }

  Future<Sala> getSala(int id) async {
    final response = await http.get(
      Uri.parse('${url}salas/$id/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      }
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 401 && data['code'] == 'token_not_valid') {
      refreshAccessToken();
      return getSala(id);
    }

    if (response.statusCode == 200) {
      return Sala.fromJson(data);
    }

    throw Exception(response.statusCode);
  }

  Future<Sala?> createSala(String? password) async {
    final response = await http.post(
      Uri.parse('${url}salas/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
      body: {
        'senha': password,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 401 && data['code'] == 'token_not_valid') {
      refreshAccessToken();
      return createSala(password);
    }

    if (response.statusCode == 201) {
      return Sala.fromJson(data);
    }
    
    return null;
  }

  Future<void> deleteSala(int id) async {
    final response = await http.delete(
      Uri.parse('${url}salas/$id/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      }
    );

    if (response.statusCode == 204) {
      return;
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 401 && data['code'] == 'token_not_valid') {
      refreshAccessToken();
      return deleteSala(id);
    }


  }

  Future<Sala?> joinSala(int id, String? password) async {
    final response = await http.post(
      Uri.parse('${url}salas/$id/entrar/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
      body: {
        'senha': password,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 401 && data['code'] == 'token_not_valid') {
      refreshAccessToken();
      return joinSala(id, password);
    }

    if (response.statusCode == 200) {
      
      return Sala.fromJson(data);
    }

    throw Exception(data['error']);
  }

  Future<Jogador> getJogador() async {
    final response = await http.get(
      Uri.parse('${url}jogadores/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      }
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 401 && data['code'] == 'token_not_valid') {
      refreshAccessToken();
      return getJogador();
    }

    if (response.statusCode == 200) {
      return Jogador.fromJson(data);
    }

    throw Exception('Falha ao pegar jogador');
  }

  Future<void> leaveSala(int id) async {
    final response = await http.put(
      Uri.parse('${url}salas/$id/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      }
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 401 && data['code'] == 'token_not_valid') {
      refreshAccessToken();
      return leaveSala(id);
    }

    if (response.statusCode != 204) {
      throw Exception(response.body);
    }

  }
}