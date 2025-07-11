import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatação de datas e horas

import 'agendamento_detalhes_page.dart'; // Importe a página de detalhes do agendamento, se necessário

class MeusAgendamentosPage extends StatefulWidget {
  const MeusAgendamentosPage({super.key});

  @override
  State<MeusAgendamentosPage> createState() => _MeusAgendamentosPageState();
}

class _MeusAgendamentosPageState extends State<MeusAgendamentosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, faça login para ver seus agendamentos.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _currentUser == null
          ? const Center(
              child: Text(
                'Você precisa estar logado para ver seus agendamentos.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              // Busca os agendamentos do cliente logado
              stream: _firestore
                  .collection('agendamentos')
                  .where('id_cliente', isEqualTo: _currentUser!.uid)
                  .orderBy('data_hora_agendamento', descending: true) // Ordena do mais recente para o mais antigo
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'Você ainda não possui agendamentos.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var agendamento = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    // var agendamentoId = snapshot.data!.docs[index].id; // Se precisar do ID do documento

                    // Converte Timestamp para DateTime
                    DateTime dataHoraAgendamento = (agendamento['data_hora_agendamento'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text(
                            DateFormat('dd').format(dataHoraAgendamento),
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          agendamento['nome_servico'] ?? 'Serviço Desconhecido',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Profissional: ${agendamento['nome_profissional'] ?? 'Não informado'}', // Assumindo que você salvará o nome do profissional
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Data e Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(dataHoraAgendamento)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${agendamento['status_agendamento'] ?? 'Pendente'}',
                              style: TextStyle(
                                color: _getStatusColor(agendamento['status_agendamento']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => AgendamentoDetalhesPage(
                              agendamentoId: snapshot.data!.docs[index].id,
                          ),
                          ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Detalhes do agendamento em ${DateFormat('dd/MM/yyyy').format(dataHoraAgendamento)}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}