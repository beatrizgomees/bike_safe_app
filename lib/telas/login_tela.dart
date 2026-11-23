import 'package:bikesafe_app/config.dart';
import 'package:bikesafe_app/telas/cadastro_tela.dart';
import 'package:bikesafe_app/view_controllers/login_view_controller.dart';
import 'package:flutter/material.dart';

/// Tela de login, no visual do projeto de telas.
/// Ao entrar (ou criar conta), chama [aoEntrar].
class LoginTela extends StatefulWidget {
  const LoginTela({super.key, required this.aoEntrar});

  final VoidCallback aoEntrar;

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  late final LoginViewController _c;

  @override
  void initState() {
    super.initState();
    _c = LoginViewController(aoEntrar: widget.aoEntrar);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _abrirCadastro() async {
    final criou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CadastroTela()),
    );

    if (criou == true) widget.aoEntrar();
  }

  Future<void> _alterarServidor() async {
    final host = TextEditingController(text: Config.host);
    final porta = TextEditingController(text: Config.apiPorta);

    final salvar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: host,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                helperText: 'Emulador Android: 10.0.2.2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: porta,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Porta da API',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );

    if (salvar == true) await _c.salvarServidor(host.text, porta.text);
  }

  /// Rótulo acima do campo, como no design.
  Widget _rotulo(ThemeData tema, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto,
          style: tema.textTheme.labelLarge?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
      );

  /// Campo branco, cantos de 12 e altura de 52, como no design.
  InputDecoration _campo(ThemeData tema, {String? dica, Widget? sufixo}) {
    OutlineInputBorder borda(Color cor, [double largura = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return InputDecoration(
      hintText: dica,
      filled: true,
      fillColor: tema.colorScheme.surface,
      suffixIcon: sufixo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: borda(tema.colorScheme.outline),
      enabledBorder: borda(tema.colorScheme.outline),
      focusedBorder: borda(tema.colorScheme.primary, 2),
      errorBorder: borda(tema.colorScheme.error),
      focusedErrorBorder: borda(tema.colorScheme.error, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AutofillGroup(
                  child: Form(
                    key: _c.form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo, nome e subtítulo
                        Center(
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: tema.colorScheme.primaryContainer,
                            child: Icon(Icons.pedal_bike,
                                size: 40, color: tema.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bike Safe',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Acidentes com ciclistas no Recife',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodyLarge
                              ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),

                        // Entrar | Criar conta. "Criar conta" abre a tela de cadastro.
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Entrar')),
                            ButtonSegment(value: true, label: Text('Criar conta')),
                          ],
                          selected: const {false},
                          showSelectedIcon: false,
                          expandedInsets: EdgeInsets.zero,
                          style: const ButtonStyle(
                            minimumSize: WidgetStatePropertyAll(Size(0, 44)),
                          ),
                          onSelectionChanged: _c.enviando
                              ? null
                              : (s) {
                                  if (s.first) _abrirCadastro();
                                },
                        ),
                        const SizedBox(height: 20),

                        // E-mail
                        _rotulo(tema, 'E-mail'),
                        TextFormField(
                          controller: _c.email,
                          enabled: !_c.enviando,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: _campo(tema, dica: 'voce@exemplo.com'),
                          validator: _c.validarEmail,
                        ),
                        const SizedBox(height: 14),

                        // Senha
                        _rotulo(tema, 'Senha'),
                        TextFormField(
                          controller: _c.senha,
                          enabled: !_c.enviando,
                          obscureText: !_c.verSenha,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _c.enviar(),
                          decoration: _campo(
                            tema,
                            dica: 'Sua senha',
                            sufixo: IconButton(
                              tooltip: _c.verSenha ? 'Ocultar senha' : 'Mostrar senha',
                              icon: Icon(_c.verSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: _c.alternarVerSenha,
                            ),
                          ),
                          validator: _c.validarSenha,
                        ),

                        // Erro do login
                        if (_c.erro != null) ...[
                          const SizedBox(height: 12),
                          Card(
                            margin: EdgeInsets.zero,
                            color: tema.colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_c.erro!,
                                  style: TextStyle(color: tema.colorScheme.onErrorContainer)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // Botão principal: pílula de 52 de altura
                        FilledButton(
                          onPressed: _c.enviando ? null : _c.enviar,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: const StadiumBorder(),
                            textStyle: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          child: _c.enviando
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 16),

                        // Servidor
                        Center(
                          child: TextButton.icon(
                            onPressed: _c.enviando ? null : _alterarServidor,
                            icon: const Icon(Icons.dns_outlined, size: 18),
                            label: Text('Servidor: ${Config.host}:${Config.apiPorta}'),
                          ),
                        ),
                      ],
                    ),
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
