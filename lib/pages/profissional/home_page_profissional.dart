import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import 'listar_servico_page.dart';
import 'cadastrar_servico_page.dart';
import 'gerenciador_horarios_page.dart';
import 'dashboard_profissional_page.dart';

class HomePageProfissional extends StatefulWidget {
  const HomePageProfissional({super.key});

  @override
  State<HomePageProfissional> createState() => _HomePageProfossionalState();
}

class _HomePageProfossionalState extends State<HomePageProfissional> {
  final AuthService _authService = AuthService();
  String _nomeUsuario = '';
  String _especialidade = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Buscar dados do usuário
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get();

        // Buscar dados do profissional
        final profissionalDoc =
            await FirebaseFirestore.instance
                .collection('profissionais')
                .doc(user.uid)
                .get();

        if (userDoc.exists && profissionalDoc.exists) {
          setState(() {
            _nomeUsuario = userDoc.data()?['nome'] ?? 'Usuário';
            _especialidade = profissionalDoc.data()?['especialidade'] ?? '';
          });
        }
      } catch (e) {
        print('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GestãoFácil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sair'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com boas-vindas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bem-vindo(a),',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nomeUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_especialidade.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _especialidade,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Estatísticas rápidas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Agendamentos Hoje',
                    '0',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Receita Mensal',
                    'R\$ 0,00',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Serviços Ativos',
                    '0',
                    Icons.medical_services,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Clientes Ativos',
                    '0',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Menu de opções
            const Text(
              'Menu Principal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Opções do menu
            _buildMenuOption(
              'Meus Serviços',
              'Gerenciar tipos de atendimento e preços',
              Icons.medical_services,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListarServicosPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuOption(
              'Cadastrar Serviço',
              'Adicionar novo tipo de atendimento',
              Icons.add_box,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CadastrarServicoPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuOption(
              'Agenda',
              'Visualizar agendamentos do dia',
              Icons.calendar_month,
              Colors.orange,
              () {
                // TODO: Implementar agenda
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardProfissionalPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),



            _buildMenuOption(
              'Horários Disponíveis',
              'Configurar seus horários de atendimento',
              Icons.schedule,
              Colors.teal,
              () {
                // TODO: Implementar horários
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GerenciarHorariosPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
