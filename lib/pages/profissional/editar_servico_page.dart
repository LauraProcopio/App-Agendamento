import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarServicoPage extends StatefulWidget {
  // Recebe o ID do serviço e os dados existentes como argumentos
  final String serviceId;
  final Map<String, dynamic> serviceData;

  const EditarServicoPage({
    super.key,
    required this.serviceId,
    required this.serviceData,
  });

  @override
  State<EditarServicoPage> createState() => _EditarServicoPageState();
}

class _EditarServicoPageState extends State<EditarServicoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();

  bool _isLoading = false;
  String? _categoriaSelecionada;
  int? _duracaoSelecionada;
  int _tempoAntecedencia = 24; // Horas
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
  void initState() {
    super.initState();
    // Preenche os controladores e variáveis de estado com os dados do serviço
    _nomeController.text = widget.serviceData['nome'] ?? '';
    _descricaoController.text = widget.serviceData['descricao'] ?? '';
    _precoController.text = (widget.serviceData['preco'] as num?)?.toStringAsFixed(2).replaceAll('.', ',') ?? '';

    _categoriaSelecionada = widget.serviceData['categoria'] as String?;
    _duracaoSelecionada = widget.serviceData['duracao_minutos'] as int?;
    _tempoAntecedencia = widget.serviceData['tempo_antecedencia_minima'] as int? ?? 24;
    _permiteReagendamento = widget.serviceData['permite_reagendamento'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _atualizarServico() async {
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
      await FirebaseFirestore.instance
          .collection('servicos')
          .doc(widget.serviceId) // Usa o ID do serviço para atualizar
          .update({
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'categoria': _categoriaSelecionada,
        'preco': double.parse(_precoController.text.replaceAll(',', '.')),
        'duracao_minutos': _duracaoSelecionada,
        'tempo_antecedencia_minima': _tempoAntecedencia,
        'permite_reagendamento': _permiteReagendamento,
        'data_atualizacao': FieldValue.serverTimestamp(), // Adiciona um campo de data de atualização
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar serviço: $e'),
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
        title: const Text('Editar Serviço'),
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
                    Icon(Icons.edit_note, color: Colors.blue, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Editar Serviço',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Altere as informações do serviço existente',
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

              // Botão de Atualizar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _atualizarServico,
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
                label: Text(_isLoading ? 'Atualizando...' : 'Atualizar Serviço'),
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
