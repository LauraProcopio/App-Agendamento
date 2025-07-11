import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatação de datas e horas

class DashboardProfissionalPage extends StatefulWidget {
  const DashboardProfissionalPage({super.key});

  @override
  State<DashboardProfissionalPage> createState() => _DashboardProfissionalPageState();
}

class _DashboardProfissionalPageState extends State<DashboardProfissionalPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      // Se o usuário não estiver logado, exibe um SnackBar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, faça login para acessar o dashboard.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard do Profissional'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _currentUser == null
          ? const Center(
              child: Text(
                'Nenhum usuário logado. Por favor, faça login.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Dashboard
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
                          'Visão Geral da Agenda',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Agendamentos Futuros',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título da seção de agendamentos
                  const Text(
                    'Próximos Agendamentos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de Agendamentos Futuros
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('agendamentos')
                        .where('id_profissional', isEqualTo: _currentUser!.uid)
                        .where('data_hora_agendamento', isGreaterThanOrEqualTo: Timestamp.now()) // Apenas agendamentos futuros
                        .orderBy('data_hora_agendamento', descending: false) // Ordena do mais próximo para o mais distante
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Erro ao carregar agendamentos: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.event_available, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  'Nenhum agendamento futuro encontrado.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true, // Para que o ListView não ocupe todo o espaço disponível
                        physics: const NeverScrollableScrollPhysics(), // Desabilita o scroll do ListView interno
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var agendamento = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          var agendamentoId = snapshot.data!.docs[index].id;

                          // Converte Timestamp para DateTime
                          DateTime dataHoraAgendamento = (agendamento['data_hora_agendamento'] as Timestamp).toDate();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  DateFormat('dd').format(dataHoraAgendamento),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                agendamento['nome_cliente'] ?? 'Cliente Desconhecido', // Assumindo que você terá o nome do cliente
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    agendamento['nome_servico'] ?? 'Serviço Não Informado', // Assumindo que você terá o nome do serviço
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy HH:mm').format(dataHoraAgendamento)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Status: ${agendamento['status_agendamento'] ?? 'Pendente'}',
                                    style: TextStyle(
                                      color: _getStatusColor(agendamento['status_agendamento']),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                                onPressed: () {
                                  // TODO: Implementar navegação para detalhes do agendamento
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Detalhes do agendamento ${agendamentoId}'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Seção para futuras estatísticas ou atalhos
                  const Text(
                    'Atalhos e Estatísticas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Exemplo de Card para estatística (pode ser preenchido com dados reais)
                  _buildStatCard(
                    'Agendamentos Confirmados (Mês)',
                    '15', // Placeholder
                    Icons.check_circle_outline,
                    Colors.indigo,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Próxima Conta a Pagar',
                    'R\$ 250,00', // Placeholder
                    Icons.money_off,
                    Colors.red,
                  ),
                  // Adicione mais cards ou atalhos conforme necessário
                ],
              ),
            ),
    );
  }

  // Função auxiliar para definir a cor do status do agendamento
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmado':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      case 'realizado':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  // Widget para os cards de estatísticas (reutilizado da HomePage)
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity, // Ocupa a largura total
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
