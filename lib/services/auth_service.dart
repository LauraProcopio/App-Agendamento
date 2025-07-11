import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Stream de mudanças de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Registrar novo usuário
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    String? especialidade, // Agora opcional, pois clientes não terão
    String tipoUsuario = 'cliente', // Novo parâmetro com valor padrão 'cliente'
  }) async {
    try {
      // Criar usuário no Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Criar documento do usuário no Firestore
      await _createUserDocument(
        uid: result.user!.uid,
        nome: nome,
        email: email,
        telefone: telefone,
        tipoUsuario: tipoUsuario, // Passa o tipo de usuário
        especialidade: especialidade, // Passa a especialidade (pode ser nula para cliente)
      );

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Criar documento do usuário no Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
    required String tipoUsuario, // Parâmetro para o tipo de usuário
    String? especialidade, // Opcional
  }) async {
    // Documento do usuário (comum para ambos os tipos)
    await _firestore.collection('usuarios').doc(uid).set({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'tipo_usuario': tipoUsuario, // Salva o tipo de usuário
      'ativo': true,
      'data_cadastro': FieldValue.serverTimestamp(),
      'data_ultima_atualizacao': FieldValue.serverTimestamp(),
    });

    // Lógica condicional para criar documento de perfil específico
    if (tipoUsuario == 'profissional') {
      await _firestore.collection('profissionais').doc(uid).set({
        'id_usuario': uid,
        'especialidade': especialidade, // Especialidade é obrigatória para profissional
        'valor_consulta_padrao': 0.0,
        'tempo_consulta_padrao': 60,
        'aceita_agendamento_online': true,
        'dias_atendimento': ['segunda', 'terca', 'quarta', 'quinta', 'sexta'],
        'horario_funcionamento': {
          'inicio': '08:00',
          'fim': '18:00',
        },
      });
    } else if (tipoUsuario == 'cliente') {
      await _firestore.collection('clientes').doc(uid).set({
        'id_usuario': uid,
        // Adicione outros campos específicos do cliente aqui, se houver
        'cpf': '', // Exemplo
        'data_nascimento': null, // Exemplo
        'endereco_completo': '', // Exemplo
        'preferencia_pagamento': '', // Exemplo
        'aceita_lembretes': true, // Exemplo
      });
    }
  }

  // Novo método para obter o tipo de usuário logado
  Future<String?> getUserType(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        return data?['tipo_usuario'] as String?;
      }
      return null;
    } catch (e) {
      print('Erro ao obter tipo de usuário: $e');
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Resetar senha
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Tratar exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'A senha é muito fraca';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}