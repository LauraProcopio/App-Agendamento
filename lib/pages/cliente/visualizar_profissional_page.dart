import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para verificar se o cliente está logado

import 'servicos_do_profissional_page.dart';
// Você pode querer importar a página de detalhes do profissional ou de agendamento aqui
// import 'package:your_app_name/pages/client/professional_detail_page.dart'; // Exemplo

class VisualizarProfissionaisPage extends StatefulWidget {
  const VisualizarProfissionaisPage({super.key});

  @override
  State<VisualizarProfissionaisPage> createState() =>
      _VisualizarProfissionaisPageState();
}

class _VisualizarProfissionaisPageState
    extends State<VisualizarProfissionaisPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser; // Para verificar o status de login do cliente

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Opcional: Se esta página só puder ser acessada por clientes logados, adicione uma verificação
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, faça login para visualizar profissionais.',
            ),
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
        title: const Text('Profissionais Disponíveis'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _currentUser == null
              ? const Center(
                child: Text(
                  'Você precisa estar logado para ver os profissionais.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                // Busca todos os documentos na coleção 'profissionais'
                stream: _firestore.collection('profissionais').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar profissionais: ${snapshot.error}',
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Nenhum profissional encontrado no momento.',
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
                      var profissionalDoc = snapshot.data!.docs[index];
                      var profissionalData =
                          profissionalDoc.data() as Map<String, dynamic>;
                      String profissionalId =
                          profissionalDoc.id; // O UID do profissional

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            _firestore
                                .collection('usuarios')
                                .doc(profissionalId)
                                .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 100, // Altura para o placeholder do card
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          if (userSnapshot.hasError ||
                              !userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            // Lidar com erro ou usuário não encontrado
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.error),
                                ),
                                title: Text('Profissional ID: $profissionalId'),
                                subtitle: const Text(
                                  'Dados do usuário não encontrados.',
                                ),
                              ),
                            );
                          }

                          var userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          String nomeProfissional =
                              userData['nome'] ?? 'Nome Desconhecido';
                          String especialidade =
                              profissionalData['especialidade'] ??
                              'Não informada';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  nomeProfissional.isNotEmpty
                                      ? nomeProfissional[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                nomeProfissional,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              subtitle: Text(
                                'Especialidade: $especialidade',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ServicosDoProfissionalPage(
                                          profissionalId: profissionalId,
                                          profissionalNome: nomeProfissional,
                                        ),
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Clicou no profissional: $nomeProfissional (ID: $profissionalId)',
                                    ),
                                  ),
                                );
                                // Exemplo de navegação:
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => ProfessionalDetailPage(profissionalId: profissionalId),
                                //   ),
                                // );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}
