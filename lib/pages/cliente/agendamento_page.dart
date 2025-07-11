import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Importar o table_calendar

class AgendamentoPage extends StatefulWidget {
  final String profissionalId;
  final String profissionalNome;
  final String serviceId;
  final Map<String, dynamic> serviceData;

  const AgendamentoPage({
    super.key,
    required this.profissionalId,
    required this.profissionalNome,
    required this.serviceId,
    required this.serviceData,
  });

  @override
  State<AgendamentoPage> createState() => _AgendamentoPageState();
}

class _AgendamentoPageState extends State<AgendamentoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<TimeOfDay> _availableSlots = [];
  TimeOfDay? _selectedSlot;

  bool _isLoadingSlots = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, faça login para agendar serviços.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    } else {
      _selectedDay = _focusedDay;
      // Adicione um pequeno atraso para garantir que o usuário esteja totalmente autenticado
      // antes de tentar buscar os slots, especialmente em cold starts.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Verifica se o widget ainda está montado
          _fetchAvailableSlots(_selectedDay!);
        }
      });
    }
  }

  // Mapeamento de números de dia da semana para nomes (igual ao GerenciarHorariosPage)
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

  // Função para buscar horários disponíveis e agendamentos existentes
  Future<void> _fetchAvailableSlots(DateTime date) async {
    // Adicionado print para depuração
    print('DEBUG: _fetchAvailableSlots chamado para o dia: $date');
    print('DEBUG: Current User UID: ${_currentUser?.uid}');
    print('DEBUG: Profissional ID: ${widget.profissionalId}');

    if (_currentUser == null) {
      print('DEBUG: _currentUser é nulo, não buscando slots.');
      setState(() {
        _isLoadingSlots = false;
      });
      return;
    }

    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedSlot = null;
    });

    try {
      // 1. Buscar horários configurados pelo profissional para o dia da semana selecionado
      final int weekday =
          date.weekday == 7 ? 0 : date.weekday; // Convert Sunday (7) to 0
      print('DEBUG: Buscando horários para o dia da semana: $weekday');

      final horariosSnapshot =
          await _firestore
              .collection('horarios_disponiveis')
              .where('id_profissional', isEqualTo: widget.profissionalId)
              .where('dia_semana', isEqualTo: weekday)
              .where('ativo', isEqualTo: true)
              .get();

      print(
        'DEBUG: Horários configurados encontrados: ${horariosSnapshot.docs.length}',
      );

      List<Map<String, dynamic>> configuredHours = [];
      for (var doc in horariosSnapshot.docs) {
        var data = doc.data();
        DateTime? vigenciaInicio =
            (data['data_vigencia_inicio'] as Timestamp?)?.toDate();
        DateTime? vigenciaFim =
            (data['data_vigencia_fim'] as Timestamp?)?.toDate();

        // Verifica se o dia selecionado está dentro do período de vigência do horário
        bool isWithinVigency = true;
        if (vigenciaInicio != null && date.isBefore(vigenciaInicio)) {
          isWithinVigency = false;
        }
        if (vigenciaFim != null && date.isAfter(vigenciaFim)) {
          isWithinVigency = false;
        }

        if (isWithinVigency) {
          configuredHours.add(data);
        }
      }

      // 2. Buscar agendamentos existentes para o profissional no dia selecionado
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print('DEBUG: Buscando agendamentos entre $startOfDay e $endOfDay');

      final agendamentosSnapshot =
          await _firestore
              .collection('agendamentos')
              .where('id_profissional', isEqualTo: widget.profissionalId)
              .where(
                'data_hora_agendamento',
                isGreaterThanOrEqualTo: startOfDay,
              )
              .where('data_hora_agendamento', isLessThanOrEqualTo: endOfDay)
              .get();

      print(
        'DEBUG: Agendamentos existentes encontrados: ${agendamentosSnapshot.docs.length}',
      );

      List<Map<String, dynamic>> bookedSlots =
          agendamentosSnapshot.docs.map((doc) => doc.data()).toList();

      // 3. Calcular slots disponíveis
      List<TimeOfDay> slots = [];
      int serviceDuration =
          widget.serviceData['duracao_minutos'] ?? 60; // Duração do serviço

      for (var config in configuredHours) {
        TimeOfDay start = TimeOfDay(
          hour: int.parse(config['hora_inicio'].split(':')[0]),
          minute: int.parse(config['hora_inicio'].split(':')[1]),
        );
        TimeOfDay end = TimeOfDay(
          hour: int.parse(config['hora_fim'].split(':')[0]),
          minute: int.parse(config['hora_fim'].split(':')[1]),
        );

        DateTime currentSlotStart = DateTime(
          date.year,
          date.month,
          date.day,
          start.hour,
          start.minute,
        );
        DateTime periodEnd = DateTime(
          date.year,
          date.month,
          date.day,
          end.hour,
          end.minute,
        );

        while (currentSlotStart
                .add(Duration(minutes: serviceDuration))
                .isBefore(periodEnd) ||
            currentSlotStart
                .add(Duration(minutes: serviceDuration))
                .isAtSameMomentAs(periodEnd)) {
          bool isBooked = false;
          for (var booked in bookedSlots) {
            DateTime bookedStart =
                (booked['data_hora_agendamento'] as Timestamp).toDate();
            DateTime bookedEnd = bookedStart.add(
              Duration(minutes: booked['duracao_real'] ?? 0),
            );

            // Verifica se o slot atual se sobrepõe a um agendamento existente
            if (currentSlotStart.isBefore(bookedEnd) &&
                currentSlotStart
                    .add(Duration(minutes: serviceDuration))
                    .isAfter(bookedStart)) {
              isBooked = true;
              break;
            }
          }

          // Verifica se o slot já passou (para o dia atual)
          if (date.day == DateTime.now().day &&
              currentSlotStart.isBefore(DateTime.now())) {
            isBooked = true; // Não mostrar horários no passado para o dia atual
          }

          if (!isBooked) {
            slots.add(TimeOfDay.fromDateTime(currentSlotStart));
          }
          currentSlotStart = currentSlotStart.add(
            Duration(minutes: serviceDuration),
          ); // Avança para o próximo slot
        }
      }
      setState(() {
        _availableSlots = slots;
      });
      print('DEBUG: Slots disponíveis calculados: ${_availableSlots.length}');
    } catch (e) {
      print('DEBUG: Erro ao buscar horários disponíveis: $e'); // Print do erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar horários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  // Função para lidar com a seleção de um dia no calendário
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay; // Atualiza o dia focado também
      _selectedSlot = null; // Limpa o slot selecionado ao mudar de dia
    });
    _fetchAvailableSlots(
      selectedDay,
    ); // Busca novos slots para o dia selecionado
  }

  // Função para agendar o serviço
  Future<void> _bookAppointment() async {
    if (_currentUser == null || _selectedDay == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma data e um horário para agendar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final DateTime finalAppointmentDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedSlot!.hour,
        _selectedSlot!.minute,
      );

      // Verificar se o slot ainda está disponível no Firestore (para evitar concorrência)
      final existingAppointments =
          await _firestore
              .collection('agendamentos')
              .where('id_profissional', isEqualTo: widget.profissionalId)
              .where(
                'data_hora_agendamento',
                isEqualTo: finalAppointmentDateTime,
              )
              .get();

      if (existingAppointments.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Este horário não está mais disponível. Por favor, escolha outro.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        _fetchAvailableSlots(_selectedDay!); // Recarrega os slots
        return;
      }

      await _firestore.collection('agendamentos').add({
        'id_cliente': _currentUser!.uid,
        'id_profissional': widget.profissionalId,
        'nome_profissional': widget.profissionalNome, // <--- Adicionado aqui!
        'id_servico': widget.serviceId,
        'data_hora_agendamento': finalAppointmentDateTime,
        'duracao_real': widget.serviceData['duracao_minutos'],
        'status_agendamento': 'pendente', // Ou 'confirmado' se for automático
        'valor_cobrado': widget.serviceData['preco'],
        'observacoes_cliente': '', // Pode ser um campo de texto no futuro
        'data_criacao': FieldValue.serverTimestamp(),
        // Adicione nome do cliente e nome do serviço para facilitar a exibição no dashboard do profissional
        'nome_cliente':
            _currentUser!.displayName ??
            _currentUser!.email, // Ou buscar do Firestore
        'nome_servico': widget.serviceData['nome'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna para a tela anterior
        // Se você quiser voltar para a home do cliente após agendar, use:
        // Navigator.pushReplacementNamed(context, '/');
        // Ou volte para a lista de serviços (se for o caso)
        // Navigator.pop(context, true); // Volta para a lista de serviços (ou dashboard do cliente)
      }
    } catch (e) {
      print('Erro ao agendar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao agendar serviço: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String precoFormatado = oCcy.format(widget.serviceData['preco'] ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Serviço'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detalhes do Serviço e Profissional
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceData['nome'] ?? 'Serviço Desconhecido',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Profissional: ${widget.profissionalNome}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Preço: $precoFormatado',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer, size: 18, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Duração: ${widget.serviceData['duracao_minutos'] ?? '0'} min',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seleção de Data
            const Text(
              'Selecione a Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(
                  const Duration(days: 365),
                ), // 1 ano para frente
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible:
                      false, // Oculta o botão de formato (semanal/mensal)
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.blue.shade700,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.blue.shade700,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seleção de Horário
            const Text(
              'Selecione o Horário',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoadingSlots
                ? const Center(child: CircularProgressIndicator())
                : _availableSlots.isEmpty
                ? Center(
                  child: Text(
                    _selectedDay == null
                        ? 'Selecione uma data para ver os horários.'
                        : 'Nenhum horário disponível para ${_getDiaSemanaNome(_selectedDay!.weekday == 7 ? 0 : _selectedDay!.weekday)} ${_selectedDay!.day}/${_selectedDay!.month}.',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
                : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 colunas de horários
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio:
                        2.5, // Proporção para os botões de horário
                  ),
                  itemCount: _availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = _availableSlots[index];
                    final isSelected = _selectedSlot == slot;
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedSlot = slot;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected
                                ? Colors.blue
                                : Colors.blue.withOpacity(0.1),
                        foregroundColor:
                            isSelected ? Colors.white : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                isSelected ? Colors.blue : Colors.blue.shade200,
                          ),
                        ),
                        elevation: isSelected ? 4 : 1,
                      ),
                      child: Text(
                        slot.format(context),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
            const SizedBox(height: 32),

            // Botão de Agendar
            ElevatedButton.icon(
              onPressed:
                  _isBooking || _selectedSlot == null ? null : _bookAppointment,
              icon:
                  _isBooking
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.check_circle_outline),
              label: Text(
                _isBooking ? 'Agendando...' : 'Confirmar Agendamento',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
