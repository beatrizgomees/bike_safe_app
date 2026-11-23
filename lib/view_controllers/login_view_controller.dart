import 'package:bikesafe_app/auth/auth_service.dart';
import 'package:bikesafe_app/config.dart';
import 'package:bikesafe_app/view_controllers/validadores.dart';
import 'package:flutter/material.dart';

class LoginViewController extends ChangeNotifier {
  LoginViewController({required this.aoEntrar, AuthService? auth})
      : _auth = auth ?? AuthService();

  final VoidCallback aoEntrar;
  final AuthService _auth;

  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final senha = TextEditingController();

  bool _verSenha = false;
  bool _enviando = false;
  bool _descartado = false;
  String? _erro;

  bool get verSenha => _verSenha;
  bool get enviando => _enviando;
  String? get erro => _erro;

  String? validarEmail(String? v) => Validadores.email(v);
  String? validarSenha(String? v) => Validadores.senha(v);

  void alternarVerSenha() {
    _verSenha = !_verSenha;
    _avisar();
  }

  Future<bool> salvarServidor(String host, String porta) async {
    final p = int.tryParse(porta.trim());

    if (host.trim().isEmpty || p == null || p < 1 || p > 65535) {
      _erro = 'Confira o endereço e a porta do servidor.';
      _avisar();

      return false;
    }

    await Config.salvarServidor(host: host, apiPorta: '$p', brokerPorta: Config.brokerPorta);

    _erro = null;
    _avisar();

    return true;
  }

  Future<void> enviar() async {
    if (_enviando || !(form.currentState?.validate() ?? false)) return;

    _enviando = true;
    _erro = null;
    _avisar();

    try {
      final sessao = await _auth.entrar(email.text.trim(), senha.text);

      await Config.salvarSessao(token: sessao.token, nome: sessao.nome, email: sessao.email);

      aoEntrar(); // a tela sai de cena; não precisa destravar o botão
    } on ErroAuth catch (e) {
      _enviando = false;
      _erro = e.mensagem;
      _avisar();
    } catch (_) {
      _enviando = false;
      _erro = 'Algo deu errado. Tente de novo.';
      _avisar();
    }
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    email.dispose();
    senha.dispose();
    super.dispose();
  }
}
