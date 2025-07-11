import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart'; // Ajuste o caminho conforme necessário
import 'visualizar_profissional_page.dart'; // Importe a página de visualizar profissionais
import 'meus_agendamentos_page.dart'; // Importe a página de Meus Agendamentos

class HomePageCliente extends StatefulWidget {
  const HomePageCliente({super.key});

  @override
  State<HomePageCliente> createState() => _HomePageClienteState();
}

class _HomePageClienteState extends State<HomePageCliente> {
  final AuthService _authService = AuthService();
  String _nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            _nomeUsuario = userDoc.data()?['nome'] ?? 'Cliente';
          });
        }
      } catch (e) {
        print('Erro ao carregar dados do cliente: $e');
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
        title: const Text('GestãoFácil - Cliente'),
        backgroundColor: Colors.green, // Cor diferente para diferenciar
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
            // Header com boas-vindas para o Cliente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá,',
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
                  const SizedBox(height: 8),
                  const Text(
                    'Encontre e agende seus serviços!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'O que você gostaria de fazer?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Opções do menu para o Cliente
            _buildMenuOption(
              'Encontrar Profissionais',
              'Busque e agende serviços com os melhores profissionais',
              Icons.search,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VisualizarProfissionaisPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuOption(
              'Meus Agendamentos',
              'Visualize, reagende ou cancele seus serviços',
              Icons.calendar_month,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeusAgendamentosPage(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Meus Agendamentos (cliente) em desenvolvimento',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuOption(
              'Histórico de Pagamentos',
              'Acompanhe seus pagamentos e recibos',
              Icons.receipt,
              Colors.purple,
              () {
                // TODO: Implementar página de Histórico de Pagamentos para o cliente
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Histórico de Pagamentos (cliente) em desenvolvimento',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
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
