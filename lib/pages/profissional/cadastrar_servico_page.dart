import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastrarServicoPage extends StatefulWidget {
  const CadastrarServicoPage({super.key});

  @override
  State<CadastrarServicoPage> createState() => _CadastrarServicoPageState();
}

class _CadastrarServicoPageState extends State<CadastrarServicoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  // final _duracaoController = TextEditingController(); // Removed as it will be a Dropdown

  bool _isLoading = false;
  String? _categoriaSelecionada;
  int? _duracaoSelecionada; // New variable for selected duration
  int _tempoAntecedencia = 24; // horas
  bool _permiteReagendamento = true;

  // Categorias de serviços
  final List<String> _categorias = [
    'Consulta',
    'Exame',
    'Procedimento',
    'Terapia',
    'Avaliação',
    'Retorno',
    'Urgência',
    'Outro',
  ];

  // Opções de duração em minutos
  final List<int> _opcoesDuracao = [15, 30, 45, 60, 90, 120, 180];

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    // _duracaoController.dispose(); // Removed
    super.dispose();
  }

  Future<void> _salvarServico() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('servicos').add({
        'id_profissional': user.uid,
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'categoria': _categoriaSelecionada,
        'preco': double.parse(_precoController.text.replaceAll(',', '.')),
        'duracao_minutos': _duracaoSelecionada, // Use selected duration
        'tempo_antecedencia_minima': _tempoAntecedencia,
        'permite_reagendamento': _permiteReagendamento,
        'ativo': true,
        'data_criacao': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar serviço: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Serviço'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_box, color: Colors.blue, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novo Serviço',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Preencha as informações do serviço',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nome do serviço
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Serviço',
                  prefixIcon: Icon(Icons.medical_services),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Consulta Médica',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome do serviço';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoria
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _categoriaSelecionada = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione uma categoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'Descreva o serviço oferecido...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Preço e Duração na mesma linha
              Row(
                children: [
                  // Preço
                  Expanded(
                    child: TextFormField(
                      controller: _precoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        hintText: '100,00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite o preço';
                        }
                        final preco = double.tryParse(value.replaceAll(',', '.'));
                        if (preco == null || preco <= 0) {
                          return 'Preço inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Duração (Dropdown)
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _duracaoSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Duração (min)',
                        prefixIcon: Icon(Icons.timer),
                        border: OutlineInputBorder(),
                      ),
                      items: _opcoesDuracao.map((duracao) {
                        return DropdownMenuItem(
                          value: duracao,
                          child: Text('$duracao min'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _duracaoSelecionada = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione a duração';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tempo de Antecedência Mínima
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tempo de Antecedência Mínima para Agendamento',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _tempoAntecedencia.toDouble(),
                              min: 1,
                              max: 72, // Ex: até 3 dias
                              divisions: 71, // 72 - 1 = 71 divisions
                              label: '${_tempoAntecedencia} horas',
                              onChanged: (value) {
                                setState(() {
                                  _tempoAntecedencia = value.round();
                                });
                              },
                            ),
                          ),
                          Text('${_tempoAntecedencia} horas'),
                        ],
                      ),
                      Text(
                        'Os clientes só poderão agendar este serviço com pelo menos $_tempoAntecedencia horas de antecedência.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Permite Reagendamento
              SwitchListTile(
                title: const Text('Permitir Reagendamento'),
                subtitle: const Text('Permitir que os clientes reagendem este serviço após o agendamento inicial.'),
                value: _permiteReagendamento,
                onChanged: (bool value) {
                  setState(() {
                    _permiteReagendamento = value;
                  });
                },
                secondary: const Icon(Icons.event_repeat),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              const SizedBox(height: 24),

              // Botão de Salvar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _salvarServico,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Salvando...' : 'Salvar Serviço'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Espaçamento extra no final
            ],
          ),
        ),
      ),
    );
  }
}