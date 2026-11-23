import 'package:firebase_auth/firebase_auth.dart';

class ErroAuth implements Exception {
  ErroAuth(this.mensagem, {this.codigo});

  final String mensagem;
  final String? codigo; // código do Firebase (ex.: 'email-already-in-use')

  @override
  String toString() => mensagem;
}

class Sessao {
  Sessao({required this.token, required this.nome, required this.email});

  final String token, nome, email;

  static Future<Sessao> deUsuario(User u, {String? nome}) async => Sessao(
        token: await u.getIdToken() ?? '',
        nome: nome ?? u.displayName ?? '',
        email: u.email ?? '',
      );
}

/// Login e cadastro com Firebase Authentication (e-mail e senha).
/// As contas ficam no projeto Firebase (console > Authentication > Users).
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Usuário com sessão ativa (o Firebase lembra o login entre aberturas do app).
  User? get usuarioAtual => _auth.currentUser;

  Future<Sessao> entrar(String email, String senha) => _tentar(() async {
        final cred = await _auth.signInWithEmailAndPassword(email: email, password: senha);

        return Sessao.deUsuario(cred.user!);
      });

  Future<Sessao> registrar(String nome, String email, String senha) => _tentar(() async {
        final cred =
            await _auth.createUserWithEmailAndPassword(email: email, password: senha);
        final u = cred.user!;

        await u.updateDisplayName(nome);

        return Sessao.deUsuario(u, nome: nome);
      });

  Future<void> sair() => _auth.signOut();

  Future<T> _tentar<T>(Future<T> Function() acao) async {
    try {
      return await acao();
    } on FirebaseAuthException catch (e) {
      throw ErroAuth(_mensagem(e), codigo: e.code);
    }
  }

  static String _mensagem(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' => 'Já existe uma conta com este e-mail.',
        'invalid-email' => 'E-mail inválido.',
        'weak-password' => 'Senha fraca. Use pelo menos 6 caracteres.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' ||
        'INVALID_LOGIN_CREDENTIALS' =>
          'E-mail ou senha incorretos.',
        'user-disabled' => 'Esta conta foi desativada.',
        'too-many-requests' => 'Muitas tentativas. Espere um pouco e tente de novo.',
        'network-request-failed' => 'Sem conexão com a internet.',
        'operation-not-allowed' =>
          'Login por e-mail/senha não está ativado no Firebase.',
        _ => e.message ?? 'Erro ao autenticar (${e.code}).',
      };
}
