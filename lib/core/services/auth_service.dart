import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  // Stream do estado da autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obter usuário atual
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await _googleSignIn.initialize();
      } catch (e) {
        print('Erro ao inicializar GoogleSignIn: $e');
      }
      _isInitialized = true;
    }
  }

  // Login com o Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // Inicia o fluxo de autenticação do Google (lança exceção se cancelado)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Cria uma nova credencial de autenticação do Firebase (usando idToken)
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Autentica no Firebase com a credencial
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        print('Login cancelado pelo usuário.');
        return null;
      }
      print(
        'Erro GoogleSignInException no login com Google: ${e.code} - ${e.description}',
      );
      rethrow;
    } catch (e) {
      print('Erro no login com Google: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

// Providers do Riverpod
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
