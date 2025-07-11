import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatação de datas e moeda

class AgendamentoDetalhesPage extends StatefulWidget {
  final String agendamentoId;

  const AgendamentoDetalhesPage({
    super.key,
    required this.agendamentoId,
  });

  @override
  State<AgendamentoDetalhesPage> createState() => _AgendamentoDetalhesPageState();
}

class _AgendamentoDetalhesPageState extends State<AgendamentoDetalhesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Função para exibir um diálogo de confirmação
  Future<bool?> _showConfirmationDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Sim'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Função para cancelar agendamento
  Future<void> _cancelarAgendamento() async {
    final bool? confirm = await _showConfirmationDialog(
      'Cancelar Agendamento',
      'Tem certeza que deseja cancelar este agendamento?',
    );

    if (confirm == true) {
      try {
        await _firestore.collection('agendamentos').doc(widget.agendamentoId).update({
          'status_agendamento': 'cancelado',
          'motivo_cancelamento': 'Cancelado pelo cliente', // Pode ser mais detalhado
          'data_atualizacao': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agendamento cancelado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volta para a lista de agendamentos
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cancelar agendamento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Agendamento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Escuta em tempo real as mudanças no documento de agendamento específico
        stream: _firestore.collection('agendamentos').doc(widget.agendamentoId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar detalhes: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Agendamento não encontrado.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var agendamentoData = snapshot.data!.data() as Map<String, dynamic>;

          // Converte Timestamp para DateTime
          DateTime dataHoraAgendamento = (agendamentoData['data_hora_agendamento'] as Timestamp).toDate();
          final oCcy = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          String precoFormatado = oCcy.format(agendamentoData['valor_cobrado'] ?? 0.0);

          bool canCancelOrReschedule = agendamentoData['status_agendamento'] == 'pendente' ||
                                      agendamentoData['status_agendamento'] == 'confirmado';
          bool isFutureAppointment = dataHoraAgendamento.isAfter(DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agendamentoData['nome_servico'] ?? 'Serviço Desconhecido',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Profissional: ${agendamentoData['nome_profissional'] ?? 'Não informado'}',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(dataHoraAgendamento)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Text(
                              'Hora: ${DateFormat('HH:mm').format(dataHoraAgendamento)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Text(
                              'Duração: ${agendamentoData['duracao_real'] ?? '0'} min',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Preço: $precoFormatado',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _getStatusColor(agendamentoData['status_agendamento']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                agendamentoData['status_agendamento'] ?? 'Pendente',
                                style: TextStyle(
                                  color: _getStatusColor(agendamentoData['status_agendamento']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Observações: ${agendamentoData['observacoes_cliente'] ?? 'Nenhuma observação.'}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botões de Ação (Reagendar, Cancelar)
                if (canCancelOrReschedule && isFutureAppointment) ...[
                  // Botão Reagendar
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implementar lógica de reagendamento
                      // Isso provavelmente levaria para uma versão pré-preenchida da AgendamentoPage
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade de Reagendar em desenvolvimento.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_repeat),
                    label: const Text('Reagendar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50), // Garante largura total
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botão Cancelar
                  ElevatedButton.icon(
                    onPressed: _cancelarAgendamento,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar Agendamento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50), // Garante largura total
                    ),
                  ),
                ],
                if (!isFutureAppointment && agendamentoData['status_agendamento'] != 'cancelado')
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Este agendamento já foi ${agendamentoData['status_agendamento'] == 'realizado' ? 'realizado' : 'concluído'} ou está no passado.',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
