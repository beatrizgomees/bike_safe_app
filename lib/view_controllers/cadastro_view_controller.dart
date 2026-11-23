import 'package:bikesafe_app/auth/auth_service.dart';
import 'package:bikesafe_app/config.dart';
import 'package:bikesafe_app/view_controllers/validadores.dart';
import 'package:flutter/material.dart';

/// Estado e regras da tela de cadastro.
class CadastroViewController extends ChangeNotifier {
  CadastroViewController({AuthService? auth}) : _auth = auth ?? AuthService();

  final AuthService _auth;

  final form = GlobalKey<FormState>();
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final confirmarSenha = TextEditingController();

  bool _verSenha = false;
  bool _enviando = false;
  bool _descartado = false;
  String? _erro;

  bool get verSenha => _verSenha;
  bool get enviando => _enviando;
  String? get erro => _erro;

  String? validarNome(String? v) => Validadores.nome(v);
  String? validarEmail(String? v) => Validadores.email(v);
  String? validarSenha(String? v) => Validadores.senha(v);
  String? validarConfirmacao(String? v) =>
      v != senha.text ? 'As senhas não conferem' : null;

  void alternarVerSenha() {
    _verSenha = !_verSenha;
    _avisar();
  }

  /// Cria a conta e já salva a sessão. Retorna true se deu certo.
  Future<bool> criarConta() async {
    if (_enviando || !(form.currentState?.validate() ?? false)) return false;

    _enviando = true;
    _erro = null;
    _avisar();

    try {
      final sessao = await _auth.registrar(
        nome.text.trim(),
        email.text.trim(),
        senha.text,
      );

      await Config.salvarSessao(token: sessao.token, nome: sessao.nome, email: sessao.email);

      return true;
    } on ErroAuth catch (e) {
      _erro = e.mensagem;
    } catch (_) {
      _erro = 'Algo deu errado. Tente de novo.';
    }

    _enviando = false;
    _avisar();

    return false;
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    nome.dispose();
    email.dispose();
    senha.dispose();
    confirmarSenha.dispose();
    super.dispose();
  }
}
