// lib/services/auth_service.dart
// Autor: João Vitor Roventini
// RA: 22005168

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;
  AuthResult({required this.success, this.errorMessage, this.user});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── LOGIN ───────────────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user ?? _auth.currentUser;
      if (user == null) {
        return AuthResult(success: false, errorMessage: 'E-mail ou senha inválidos.');
      }
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        UserModel? userModel;
        if (userDoc.exists) userModel = UserModel.fromFirestore(userDoc);
        return AuthResult(success: true, user: userModel);
      } catch (_) {
        return AuthResult(success: true);
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _handleAuthError(e.code));
    } catch (e) {
      // Bug do PigeonUserDetails — verifica se o login aconteceu mesmo assim
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          UserModel? userModel;
          if (userDoc.exists) userModel = UserModel.fromFirestore(userDoc);
          return AuthResult(success: true, user: userModel);
        } catch (_) {
          return AuthResult(success: true);
        }
      }
      return AuthResult(success: false, errorMessage: 'E-mail ou senha inválidos.');
    }
  }

  // ─── CADASTRO ────────────────────────────────────────────────────────────────
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String password,
  }) async {
    String? uid;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = credential.user?.uid ?? _auth.currentUser?.uid;
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _handleAuthError(e.code));
    } catch (e) {
      // Bug do PigeonUserDetails — pega o uid do currentUser
      uid = _auth.currentUser?.uid;
      print('Auth cast error (uid=$uid): $e');
    }

    if (uid == null) {
      return AuthResult(
        success: false,
        errorMessage: 'Erro ao criar conta. Tente novamente.',
      );
    }

    // Salva no Firestore usando o uid capturado
    try {
      final userModel = UserModel(
        uid:           uid,
        nome:          nome,
        email:         email.trim(),
        saldoCarteira: 10000.00,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userModel.toMap());

      // Desloga para o usuário entrar manualmente
      await _auth.signOut();

      return AuthResult(success: true, user: userModel);

    } catch (e) {
      print('FIRESTORE ERROR: $e');
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      return AuthResult(
        success: false,
        errorMessage: 'Erro ao salvar dados: $e',
      );
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────────
  Future<void> logout() async => await _auth.signOut();

  // ─── RECUPERAÇÃO DE SENHA ─────────────────────────────────────────────────────
  Future<AuthResult> recuperarSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _handleAuthError(e.code));
    }
  }

  // ─── BUSCAR DADOS DO USUÁRIO ──────────────────────────────────────────────────
  Future<UserModel?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── ERROS ───────────────────────────────────────────────────────────────────
  String _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':         return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':         return 'Senha incorreta. Verifique e tente novamente.';
      case 'invalid-credential':     return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':   return 'Este e-mail já está cadastrado.';
      case 'weak-password':          return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':          return 'Formato de e-mail inválido.';
      case 'user-disabled':          return 'Esta conta foi desativada.';
      case 'too-many-requests':      return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'network-request-failed': return 'Sem conexão com a internet.';
      default:                       return 'Erro: $code';
    }
  }
}