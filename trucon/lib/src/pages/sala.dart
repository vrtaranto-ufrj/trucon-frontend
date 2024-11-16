import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sala.dart';
import '../models/jogador.dart';
import '../auth/auth.dart';

class SalasListPage extends StatefulWidget {
  final Conexao conexao;
  final Jogador jogador;
  const SalasListPage({
    super.key, 
    required this.conexao,
    required this.jogador,
  });

  @override
  State<SalasListPage> createState() => _SalasListPageState();
}

class _SalasListPageState extends State<SalasListPage> {
  List<Sala> _salas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalas();
  }

  Future<void> _loadSalas() async {
    setState(() => _isLoading = true);
    try {
      final salas = await widget.conexao.getSalas();
      if (mounted) {
        setState(() {
          _salas = salas ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rooms: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPasswordDialogJoin(Sala sala) async {
    late final String? password;
    try {
      final joinedSala = await widget.conexao.getSala(sala.id);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalaDetailPage(
              sala: joinedSala,
              conexao: widget.conexao,
              jogador: widget.jogador,
              salas: _salas,
            ),
          ),
        );
        _loadSalas();
        return;
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('403')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você já está em outra sala')),
          );
          return;
        }        
      }
    }
    if (mounted) {
      final passwordController = TextEditingController();
      await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter password for ${sala.nomeSalas}'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password (leave empty if none)',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Enter'),
            ),
          ],
        ),
      );
      password = passwordController.text;
    }

    try {
      final joinedSala = await widget.conexao.joinSala(sala.id, password);
      if (joinedSala != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalaDetailPage(
              sala: joinedSala,
              conexao: widget.conexao,
              jogador: widget.jogador,
              salas: _salas,
              ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join room\n${e.toString()}')),
        );
      }
    }
    _loadSalas();
  }

  Future<void> _showPasswordDialogCreate() async {
    late final String? password;
    if (mounted) {
      final passwordController = TextEditingController();
      await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter password for new room'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password (leave empty if none)',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Enter'),
            ),
          ],
        ),
      );
      password = passwordController.text;
    }

    try {
      final createdSala = await widget.conexao.createSala(password);
      if (createdSala != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalaDetailPage(
              sala: createdSala,
              conexao: widget.conexao,
              jogador: widget.jogador,
              salas: _salas,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create room\n${e.toString()}')),
        );
      }
    }
    _loadSalas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas disponíveis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPasswordDialogCreate(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedList(
              initialItemCount: _salas.length,
              itemBuilder: (context, index, animation) {
                final sala = _salas[index];
                return SizeTransition(
                  sizeFactor: animation,
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(sala.nomeSalas),
                      subtitle: Text('Jogadores: ${sala.quantidadeJogadores}/4'),
                      trailing: sala.password?.isNotEmpty == true
                          ? const Icon(Icons.lock)
                          : null,
                      onTap: () => _showPasswordDialogJoin(sala),
                      tileColor: sala.dono == widget.jogador.username 
                          ? Colors.green.withOpacity(0.3)
                          : widget.jogador.salaId == sala.id 
                              ? Colors.blue.withOpacity(0.3)
                              : null,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// sala_detail_page.dart
class SalaDetailPage extends StatefulWidget {
  final Sala sala;
  final Conexao conexao;
  final Jogador jogador;
  final List<Sala> salas;

  const SalaDetailPage({
    super.key,
    required this.sala,
    required this.conexao,
    required this.jogador,
    required this.salas,
  });

  @override
  State<SalaDetailPage> createState() => _SalaDetailPageState();
}

class _SalaDetailPageState extends State<SalaDetailPage> {
  late Timer _timer;
  late String _timeAlive;

  @override
  void initState() {
    super.initState();
    _updateTimeAlive();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeAlive());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeAlive() {
    final difference = DateTime.now().difference(widget.sala.criacao ?? DateTime.now());
    setState(() {
      _timeAlive =
            '${difference.inHours.toString().padLeft(2, '0')}:${difference.inMinutes.remainder(60).toString().padLeft(2, '0')}:${difference.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    });
  }

  Widget _buildUserSlot(String? username, int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(
                username != null ? Icons.person : Icons.person_outline,
              ),
            ),
            const SizedBox(width: 8),
            Text(username ?? 'Empty Slot ${index + 1}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sala.nomeSalas),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room age: $_timeAlive'),
                        if (widget.sala.password?.isNotEmpty == true)
                          Text('Password: ${widget.sala.password}'),
                        Text('Players: ${widget.sala.quantidadeJogadores}/4'),
                      ],
                    ),
                  ),
                ),
                if (widget.sala.dono == widget.jogador.username)
                  Card(
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        try {
                          await widget.conexao.deleteSala(widget.sala.id);
                          if (mounted) {
                            widget.jogador.salaId = null;
                            widget.salas.remove(widget.sala);
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete room: $e')),
                            );
                          }
                        }
                      },
                    ),
                  )
                else
                  Card(
                    child: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () async {
                        try {
                          await widget.conexao.leaveSala(widget.sala.id);
                          if (mounted) {
                            widget.jogador.salaId = null;
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to leave room: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Players:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            ...List.generate(4, (index) {
              final username = index < widget.sala.jogadores.length
                  ? widget.sala.jogadores[index]
                  : null;
              return _buildUserSlot(username, index);
            }),
          ],
        ),
      ),
    );
  }
}