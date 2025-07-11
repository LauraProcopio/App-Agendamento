import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatação de moeda

import 'agendamento_page.dart'; // Importar a página de agendamento aqui

class ServicosDoProfissionalPage extends StatefulWidget {
  final String profissionalId;
  final String profissionalNome; // Para exibir no AppBar, por exemplo

  const ServicosDoProfissionalPage({
    super.key,
    required this.profissionalId,
    required this.profissionalNome,
  });

  @override
  State<ServicosDoProfissionalPage> createState() => _ServicosDoProfissionalPageState();
}

class _ServicosDoProfissionalPageState extends State<ServicosDoProfissionalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Serviços de ${widget.profissionalNome}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Busca os serviços ativos do profissional selecionado
        stream: _firestore
            .collection('servicos')
            .where('id_profissional', isEqualTo: widget.profissionalId)
            .where('ativo', isEqualTo: true) // Apenas serviços ativos
            .orderBy('nome') // Ordena por nome do serviço
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar serviços: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied, size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.profissionalNome} não possui serviços ativos no momento.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var service = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var serviceId = snapshot.data!.docs[index].id;

              // Formatação de moeda
              final oCcy = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
              String precoFormatado = oCcy.format(service['preco'] ?? 0.0);

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
                    child: Icon(Icons.medical_services, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    service['nome'] ?? 'Serviço sem nome',
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
                        service['descricao'] ?? 'Sem descrição',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Preço: $precoFormatado',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.timer, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Duração: ${service['duracao_minutos'] ?? '0'} min',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Implementação da navegação para a AgendamentoPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgendamentoPage(
                          profissionalId: widget.profissionalId,
                          profissionalNome: widget.profissionalNome,
                          serviceId: serviceId,
                          serviceData: service,
                        ),
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
