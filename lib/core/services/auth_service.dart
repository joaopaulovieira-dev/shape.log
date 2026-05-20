import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // GoogleSignIn só é instanciado no mobile — evita erro no plugin web
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  GoogleSignIn get _signIn {
    _googleSignIn ??= GoogleSignIn.instance;
    return _googleSignIn!;
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized || kIsWeb) return;
    try {
      await _signIn.initialize();
    } catch (e) {
      print('Erro ao inicializar GoogleSignIn: $e');
    }
    _isInitialized = true;
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // Na web o Firebase abre o popup de OAuth diretamente
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      try {
        return await _auth.signInWithPopup(provider);
      } catch (e) {
        print('signInWithPopup falhou, tentando fallback com signInWithRedirect: $e');
        await _auth.signInWithRedirect(provider);
        return null;
      }
    }

    try {
      await _ensureInitialized();
      final GoogleSignInAccount googleUser = await _signIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        print('Login cancelado pelo usuário.');
        return null;
      }
      print('Erro GoogleSignInException: ${e.code} - ${e.description}');
      rethrow;
    } catch (e) {
      print('Erro no login com Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _ensureInitialized();
      await _signIn.signOut();
    }
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
