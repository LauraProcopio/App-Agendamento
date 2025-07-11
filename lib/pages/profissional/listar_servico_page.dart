import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cadastrar_servico_page.dart';
import 'editar_servico_page.dart'; // Importe a página de edição de serviço

// Importe a página de cadastro de serviço se você quiser navegar para ela
// import 'package:your_app_name/cadastrar_servico_page.dart'; // Ajuste o caminho conforme necessário

class ListarServicosPage extends StatefulWidget {
  const ListarServicosPage({super.key});

  @override
  State<ListarServicosPage> createState() => _ListarServicosPageState();
}

class _ListarServicosPageState extends State<ListarServicosPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    // Se o usuário não estiver logado, você pode querer redirecioná-lo
    if (_currentUser == null) {
      // Ex: Navigator.pushReplacementNamed(context, '/login');
      // Ou mostrar uma mensagem e pedir para logar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, faça login para ver seus serviços.'),
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
        title: const Text('Meus Serviços'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Força a reconstrução do StreamBuilder para recarregar os dados
                _currentUser = _auth.currentUser;
              });
            },
          ),
        ],
      ),
      body:
          _currentUser == null
              ? const Center(
                child: Text(
                  'Nenhum usuário logado. Por favor, faça login.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                // Escuta em tempo real as mudanças na coleção 'servicos'
                stream:
                    _firestore
                        .collection('servicos')
                        .where('id_profissional', isEqualTo: _currentUser!.uid)
                        .orderBy(
                          'data_criacao',
                          descending: true,
                        ) // Ordena por data de criação
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar serviços: ${snapshot.error}',
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sentiment_dissatisfied,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Você ainda não cadastrou nenhum serviço.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Você pode adicionar um botão para cadastrar serviço aqui
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CadastrarServicoPage()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Cadastrar Novo Serviço'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Se houver dados, exibe-os em uma lista
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var service =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      var serviceId =
                          snapshot
                              .data!
                              .docs[index]
                              .id; // ID do documento Firestore

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      service['nome'] ?? 'Serviço sem nome',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Ícone de status (ativo/inativo)
                                  Icon(
                                    service['ativo'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                        service['ativo'] == true
                                            ? Colors.green
                                            : Colors.red,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Categoria: ${service['categoria'] ?? 'Não informada'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Descrição: ${service['descricao'] ?? 'Sem descrição'}',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Preço: R\$ ${service['preco']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Duração: ${service['duracao_minutos'] ?? '0'} min',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Ações para o serviço (Editar, Desativar/Ativar, Excluir)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Editar Serviço',
                                    onPressed: () {
                                      // Implementar navegação para a página de edição
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (context) => EditarServicoPage(serviceId: serviceId, serviceData: service),
                                         ),
                                       );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Funcionalidade de edição para ${service['nome']}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      service['ativo'] == true
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color:
                                          service['ativo'] == true
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                    tooltip:
                                        service['ativo'] == true
                                            ? 'Desativar Serviço'
                                            : 'Ativar Serviço',
                                    onPressed: () async {
                                      // Implementar lógica para ativar/desativar
                                      await _firestore
                                          .collection('servicos')
                                          .doc(serviceId)
                                          .update({
                                            'ativo':
                                                !(service['ativo'] == true),
                                          });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            service['ativo'] == true
                                                ? 'Serviço "${service['nome']}" desativado.'
                                                : 'Serviço "${service['nome']}" ativado.',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Excluir Serviço',
                                    onPressed: () {
                                      _confirmDelete(
                                        context,
                                        serviceId,
                                        service['nome'],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navega para a página de cadastro de serviço
          // e espera o resultado (se o serviço foi cadastrado com sucesso)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastrarServicoPage(),
            ),
          );

          // Se um serviço foi cadastrado com sucesso, recarrega a lista
          if (result == true) {
            setState(() {
              _currentUser =
                  _auth.currentUser; // Força a atualização do StreamBuilder
            });
          }
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Novo Serviço',
      ),
    );
  }

  // Função para confirmar a exclusão
  Future<void> _confirmDelete(
    BuildContext context,
    String serviceId,
    String serviceName,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // O usuário deve tocar no botão
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o serviço "$serviceName"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                try {
                  await _firestore
                      .collection('servicos')
                      .doc(serviceId)
                      .delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Serviço "$serviceName" excluído com sucesso!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir serviço: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
