import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _especialidadeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Variável para armazenar o tipo de usuário selecionado
  String _tipoUsuarioSelecionado = 'profissional'; // Padrão inicial

  // Lista de especialidades (apenas para profissionais)
  final List<String> _especialidades = [
    'Medicina',
    'Odontologia',
    'Psicologia',
    'Fisioterapia',
    'Nutrição',
    'Advocacia',
    'Consultoria',
    'Estética',
    'Terapia',
    'Outro',
  ];
  String? _especialidadeSelecionada;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _especialidadeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        tipoUsuario: _tipoUsuarioSelecionado, // Passa o tipo selecionado
        especialidade: _tipoUsuarioSelecionado == 'profissional'
            ? (_especialidadeSelecionada ?? _especialidadeController.text.trim())
            : null, // Passa especialidade apenas se for profissional
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Não navegue diretamente para /home aqui.
        // O AuthWrapper no main.dart cuidará do redirecionamento.
        // Apenas feche a página de registro.
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: ${e.toString()}'),
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
        title: const Text('Criar Conta'), // Título mais genérico
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Título
                const Text(
                  'Criar Conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preencha os dados para começar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Seleção de Tipo de Usuário
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Você é:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Profissional'),
                              value: 'profissional',
                              groupValue: _tipoUsuarioSelecionado,
                              onChanged: (value) {
                                setState(() {
                                  _tipoUsuarioSelecionado = value!;
                                  _especialidadeSelecionada = null; // Limpa especialidade ao mudar
                                  _especialidadeController.clear();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Cliente'),
                              value: 'cliente',
                              groupValue: _tipoUsuarioSelecionado,
                              onChanged: (value) {
                                setState(() {
                                  _tipoUsuarioSelecionado = value!;
                                  _especialidadeSelecionada = null; // Limpa especialidade ao mudar
                                  _especialidadeController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu nome completo';
                    }
                    if (value.length < 3) {
                      return 'Nome deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu email';
                    }
                    if (!value.contains('@')) {
                      return 'Digite um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefone
                TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: '(65) 99999-9999',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu telefone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campos de Especialidade (apenas para Profissional)
                if (_tipoUsuarioSelecionado == 'profissional') ...[
                  // Especialidade (Dropdown)
                  DropdownButtonFormField<String>(
                    value: _especialidadeSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Especialidade',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    items: _especialidades.map((especialidade) {
                      return DropdownMenuItem(
                        value: especialidade,
                        child: Text(especialidade),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _especialidadeSelecionada = value;
                      });
                    },
                    validator: (value) {
                      if (_tipoUsuarioSelecionado == 'profissional' &&
                          (value == null || value.isEmpty)) {
                        return 'Selecione sua especialidade';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo personalizado se escolher "Outro"
                  if (_especialidadeSelecionada == 'Outro')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _especialidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Qual sua especialidade?',
                          prefixIcon: Icon(Icons.edit),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_especialidadeSelecionada == 'Outro' &&
                              (value == null || value.isEmpty)) {
                            return 'Digite sua especialidade';
                          }
                          return null;
                        },
                      ),
                    ),
                ],

                // Senha
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite sua senha';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar Senha
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'Senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botão Cadastrar
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Cadastrar',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),

                // Link para login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Já tem conta? Faça login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
