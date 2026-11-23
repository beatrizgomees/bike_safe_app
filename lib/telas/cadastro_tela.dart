import 'package:bikesafe_app/view_controllers/cadastro_view_controller.dart';
import 'package:flutter/material.dart';

/// Tela de cadastro. Fecha com `true` quando a conta é criada
/// (a sessão já fica salva em Config).
class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final _c = CadastroViewController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    FocusScope.of(context).unfocus();

    final ok = await _c.criarConta();

    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _c.form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: tema.colorScheme.primaryContainer,
                          child: Icon(Icons.person_add_alt_1,
                              size: 32, color: tema.colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Bem-vindo ao Bike Safe',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Preencha seus dados para criar a conta',
                          textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _c.nome,
                        enabled: !_c.enviando,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: _c.validarNome,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _c.email,
                        enabled: !_c.enviando,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: _c.validarEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _c.senha,
                        enabled: !_c.enviando,
                        obscureText: !_c.verSenha,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          helperText: 'Mínimo de 6 caracteres',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _c.verSenha ? 'Ocultar senha' : 'Mostrar senha',
                            icon: Icon(_c.verSenha ? Icons.visibility_off : Icons.visibility),
                            onPressed: _c.alternarVerSenha,
                          ),
                        ),
                        validator: _c.validarSenha,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _c.confirmarSenha,
                        enabled: !_c.enviando,
                        obscureText: !_c.verSenha,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _criarConta(),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: Icon(Icons.lock_reset),
                          border: OutlineInputBorder(),
                        ),
                        validator: _c.validarConfirmacao,
                      ),
                      if (_c.erro != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          color: tema.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_c.erro!,
                                style: TextStyle(color: tema.colorScheme.onErrorContainer)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _c.enviando ? null : _criarConta,
                        child: _c.enviando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Criar conta'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _c.enviando ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Já tenho conta — entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
