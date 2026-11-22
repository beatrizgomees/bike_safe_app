/// Validações dos formulários de login e cadastro.
class Validadores {
  static String? nome(String? v) =>
      (v == null || v.trim().length < 2) ? 'Informe seu nome' : null;

  static String? email(String? v) {
    final t = (v ?? '').trim();

    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'E-mail inválido';
  }

  static String? senha(String? v) =>
      (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null;
}
