import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatação de datas e horas

class HorarioDisponivel {
  final String id;
  final int diaSemana; // 0 = Domingo, 1 = Segunda, ..., 6 = Sábado
  final TimeOfDay horaInicio;
  final TimeOfDay horaFim;
  final bool ativo;
  final DateTime? dataVigenciaInicio;
  final DateTime? dataVigenciaFim;

  HorarioDisponivel({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
    required this.ativo,
    this.dataVigenciaInicio,
    this.dataVigenciaFim,
  });

  // Converte um documento do Firestore em um objeto HorarioDisponivel
  factory HorarioDisponivel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return HorarioDisponivel(
      id: doc.id,
      diaSemana: data['dia_semana'] ?? 0,
      horaInicio: TimeOfDay(
        hour: int.parse(data['hora_inicio'].split(':')[0]),
        minute: int.parse(data['hora_inicio'].split(':')[1]),
      ),
      horaFim: TimeOfDay(
        hour: int.parse(data['hora_fim'].split(':')[0]),
        minute: int.parse(data['hora_fim'].split(':')[1]),
      ),
      ativo: data['ativo'] ?? true,
      dataVigenciaInicio: (data['data_vigencia_inicio'] as Timestamp?)?.toDate(),
      dataVigenciaFim: (data['data_vigencia_fim'] as Timestamp?)?.toDate(),
    );
  }

  // Converte o objeto HorarioDisponivel para um mapa para o Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'dia_semana': diaSemana,
      'hora_inicio': '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
      'hora_fim': '${horaFim.hour.toString().padLeft(2, '0')}:${horaFim.minute.toString().padLeft(2, '0')}',
      'ativo': ativo,
      'data_vigencia_inicio': dataVigenciaInicio != null ? Timestamp.fromDate(dataVigenciaInicio!) : null,
      'data_vigencia_fim': dataVigenciaFim != null ? Timestamp.fromDate(dataVigenciaFim!) : null,
    };
  }
}

class GerenciarHorariosPage extends StatefulWidget {
  const GerenciarHorariosPage({super.key});

  @override
  State<GerenciarHorariosPage> createState() => _GerenciarHorariosPageState();
}

class _GerenciarHorariosPageState extends State<GerenciarHorariosPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, faça login para gerenciar horários.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  // Mapeamento de números de dia da semana para nomes
  String _getDiaSemanaNome(int dia) {
    switch (dia) {
      case 0:
        return 'Domingo';
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      default:
        return 'Dia Inválido';
    }
  }

  // Adicionar ou editar horário
  Future<void> _showAddEditHorarioDialog({HorarioDisponivel? horario}) async {
    final _formKey = GlobalKey<FormState>();
    int _selectedDiaSemana = horario?.diaSemana ?? 1; // Padrão: Segunda-feira
    TimeOfDay _selectedHoraInicio = horario?.horaInicio ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay _selectedHoraFim = horario?.horaFim ?? const TimeOfDay(hour: 17, minute: 0);
    bool _ativo = horario?.ativo ?? true;
    DateTime? _dataVigenciaInicio = horario?.dataVigenciaInicio;
    DateTime? _dataVigenciaFim = horario?.dataVigenciaFim;

    await showDialog(
      context: context,
      builder: (context) {
        // Mova _isLoading para dentro do StatefulBuilder para que seu estado seja gerenciado aqui
        bool _dialogIsLoading = false; 

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) { // Renomeado setState para setStateDialog
            return AlertDialog(
              title: Text(horario == null ? 'Adicionar Horário' : 'Editar Horário'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedDiaSemana,
                        decoration: const InputDecoration(labelText: 'Dia da Semana'),
                        items: List.generate(7, (index) {
                          return DropdownMenuItem(
                            value: index,
                            child: Text(_getDiaSemanaNome(index)),
                          );
                        }),
                        onChanged: (value) {
                          setStateDialog(() => _selectedDiaSemana = value!); // Use setStateDialog
                        },
                        validator: (value) {
                          if (value == null) return 'Selecione o dia da semana';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text('Hora Início: ${_selectedHoraInicio.format(context)}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedHoraInicio,
                          );
                          if (picked != null && picked != _selectedHoraInicio) {
                            setStateDialog(() { // Use setStateDialog
                              _selectedHoraInicio = picked;
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: Text('Hora Fim: ${_selectedHoraFim.format(context)}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedHoraFim,
                          );
                          if (picked != null && picked != _selectedHoraFim) {
                            setStateDialog(() { // Use setStateDialog
                              _selectedHoraFim = picked;
                            });
                          }
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Ativo'),
                        value: _ativo,
                        onChanged: (bool value) {
                          setStateDialog(() => _ativo = value); // Use setStateDialog
                        },
                      ),
                      ListTile(
                        title: Text(
                          _dataVigenciaInicio == null
                              ? 'Data de Início da Vigência'
                              : 'Início: ${DateFormat('dd/MM/yyyy').format(_dataVigenciaInicio!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _dataVigenciaInicio ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setStateDialog(() => _dataVigenciaInicio = picked); // Use setStateDialog
                          }
                        },
                      ),
                      ListTile(
                        title: Text(
                          _dataVigenciaFim == null
                              ? 'Data de Fim da Vigência'
                              : 'Fim: ${DateFormat('dd/MM/yyyy').format(_dataVigenciaFim!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _dataVigenciaFim ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setStateDialog(() => _dataVigenciaFim = picked); // Use setStateDialog
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _dialogIsLoading ? null : () async { // Use _dialogIsLoading
                    if (_formKey.currentState!.validate()) {
                      if (_selectedHoraInicio.hour > _selectedHoraFim.hour ||
                          (_selectedHoraInicio.hour == _selectedHoraFim.hour &&
                              _selectedHoraInicio.minute >= _selectedHoraFim.minute)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('A hora de início deve ser anterior à hora de fim.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_dataVigenciaInicio != null &&
                          _dataVigenciaFim != null &&
                          _dataVigenciaInicio!.isAfter(_dataVigenciaFim!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('A data de início da vigência não pode ser posterior à data de fim.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setStateDialog(() => _dialogIsLoading = true); // Use setStateDialog
                      try {
                        final newHorario = HorarioDisponivel(
                          id: horario?.id ?? '', // ID vazio para novo, ou ID existente para edição
                          diaSemana: _selectedDiaSemana,
                          horaInicio: _selectedHoraInicio,
                          horaFim: _selectedHoraFim,
                          ativo: _ativo,
                          dataVigenciaInicio: _dataVigenciaInicio,
                          dataVigenciaFim: _dataVigenciaFim,
                        );

                        if (horario == null) {
                          // Adicionar novo horário
                          await _firestore.collection('horarios_disponiveis').add({
                            ...newHorario.toFirestore(),
                            'id_profissional': _currentUser!.uid,
                            'data_criacao': FieldValue.serverTimestamp(),
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Horário adicionado com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          // Atualizar horário existente
                          await _firestore.collection('horarios_disponiveis').doc(horario.id).update({
                            ...newHorario.toFirestore(),
                            'data_atualizacao': FieldValue.serverTimestamp(),
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Horário atualizado com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao salvar horário: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setStateDialog(() => _dialogIsLoading = false); // Use setStateDialog
                      }
                    }
                  },
                  child: _dialogIsLoading // Use _dialogIsLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(horario == null ? 'Adicionar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Função para confirmar a exclusão
  Future<void> _confirmDelete(BuildContext context, String horarioId, String horarioDesc) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir o horário $horarioDesc?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _firestore.collection('horarios_disponiveis').doc(horarioId).delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Horário $horarioDesc excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir horário: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Horários'),
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
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('horarios_disponiveis')
                  .where('id_profissional', isEqualTo: _currentUser!.uid)
                  .orderBy('dia_semana')
                  .orderBy('hora_inicio')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar horários: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'Você ainda não configurou nenhum horário disponível.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final horario = HorarioDisponivel.fromFirestore(snapshot.data!.docs[index]);
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getDiaSemanaNome(horario.diaSemana),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Icon(
                                  horario.ativo ? Icons.check_circle : Icons.cancel,
                                  color: horario.ativo ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${horario.horaInicio.format(context)} - ${horario.horaFim.format(context)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (horario.dataVigenciaInicio != null || horario.dataVigenciaFim != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Vigência: '
                                  '${horario.dataVigenciaInicio != null ? DateFormat('dd/MM/yyyy').format(horario.dataVigenciaInicio!) : 'Desde o início'} '
                                  '- '
                                  '${horario.dataVigenciaFim != null ? DateFormat('dd/MM/yyyy').format(horario.dataVigenciaFim!) : 'Sem fim'}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Editar Horário',
                                  onPressed: () => _showAddEditHorarioDialog(horario: horario),
                                ),
                                IconButton(
                                  icon: Icon(
                                    horario.ativo ? Icons.visibility_off : Icons.visibility,
                                    color: horario.ativo ? Colors.orange : Colors.green,
                                  ),
                                  tooltip: horario.ativo ? 'Desativar Horário' : 'Ativar Horário',
                                  onPressed: () async {
                                    await _firestore.collection('horarios_disponiveis').doc(horario.id).update(
                                      {'ativo': !horario.ativo},
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          horario.ativo
                                              ? 'Horário desativado.'
                                              : 'Horário ativado.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Excluir Horário',
                                  onPressed: () {
                                    _confirmDelete(
                                      context,
                                      horario.id,
                                      '${_getDiaSemanaNome(horario.diaSemana)} de ${horario.horaInicio.format(context)} a ${horario.horaFim.format(context)}',
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
        onPressed: () => _showAddEditHorarioDialog(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Novo Horário',
      ),
    );
  }
}
