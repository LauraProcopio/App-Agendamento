import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Adicionar import para Firestore

// Importe o arquivo gerado pelo FlutterFire CLI
// Certifique-se de que o caminho está correto para o seu projeto
import 'firebase_options.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
// Importe as novas HomePages
import 'pages/profissional/home_page_profissional.dart'; // Assumindo que você renomeou
import 'pages/cliente/home_page_cliente.dart'; // A nova HomePage para clientes
import 'services/auth_service.dart'; // Importe o AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialize o Firebase usando as opções geradas pelo FlutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GestaoFacilApp());
}

class GestaoFacilApp extends StatelessWidget {
  const GestaoFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestãoFácil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        // Remova '/home' se não for mais um ponto de entrada genérico.
        // O AuthWrapper agora é o principal para redirecionamento após o login.
        // Se você precisar de uma rota direta para a home do profissional, pode ser:
        // '/home_profissional': (context) => const HomePageProfissional(),
        // Mas para o fluxo de login/registro, o AuthWrapper é o ideal.
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta as mudanças de estado de autenticação do Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se a conexão está esperando (verificando o estado de autenticação)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se o usuário está logado
        if (snapshot.hasData) {
          final user = snapshot.data!;
          final AuthService authService = AuthService(); // Instancia o AuthService

          // Usa FutureBuilder para buscar o tipo de usuário do Firestore
          return FutureBuilder<String?>(
            future: authService.getUserType(user.uid),
            builder: (context, userTypeSnapshot) {
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userTypeSnapshot.hasError || userTypeSnapshot.data == null) {
                // Lidar com erro ou tipo de usuário não encontrado
                // Pode ser um erro, ou o documento do usuário ainda não foi criado no Firestore
                // Redireciona para o login ou uma página de erro/configuração inicial
                return const LoginPage(); // Ou uma tela de erro mais amigável
              }

              final String? userType = userTypeSnapshot.data;

              if (userType == 'profissional') {
                return const HomePageProfissional();
              } else if (userType == 'cliente') {
                return const HomePageCliente();
              } else {
                // Caso o tipo de usuário seja desconhecido ou não definido
                // Isso pode acontecer se o campo 'tipo_usuario' não estiver no Firestore
                // ou se houver um valor inesperado.
                // Redireciona para o login para que o usuário possa tentar novamente ou corrigir.
                return const LoginPage();
              }
            },
          );
        }

        // Se o usuário não está logado
        return const LoginPage();
      },
    );
  }
}
