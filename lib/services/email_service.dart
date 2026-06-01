// lib/services/email_service.dart
// Serviço para envio de e-mails reais usando SMTP (GMAIL)
// Autor: João Vitor Roventini
// RA: 22005168

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // 1. SEU GMAIL (Já preenchi para você)
  static const String _usuarioSmtp  = 'joaovitorroventini@gmail.com';

  // 2. SUA SENHA DE APP (VOCÊ PRECISA COLAR AQUI!)
  // Gere ela em: https://myaccount.google.com/apppasswords
  static const String _senhaSmtp    = 'COLE_AQUI_AS_16_LETRAS';

  Future<bool> enviarCodigoVerificacao(String emailDestino, String codigo) async {
    print('--- [DEBUG EMAIL_SERVICE] INÍCIO ---');

    // Verificação de segurança
    if (_senhaSmtp == 'COLE_AQUI_AS_16_LETRAS' || _senhaSmtp.isEmpty) {
      print('❌ ERRO: Você esqueceu de colocar a SENHA DE APP do Google no arquivo email_service.dart');
      return false;
    }

    print('Conectando ao Gmail: $_usuarioSmtp');
    final smtpServer = gmail(_usuarioSmtp, _senhaSmtp);

    final message = Message()
      ..from = const Address(_usuarioSmtp, 'Segurança MesclaInvest')
      ..recipients.add(emailDestino)
      ..subject = 'Código de Acesso: $codigo'
      ..html = """
        <div style="font-family: sans-serif; padding: 20px;">
          <h2 style="color: #00D4AA;">Seu Código MesclaInvest</h2>
          <p>Use o código abaixo para completar seu login:</p>
          <h1 style="background: #f4f4f4; padding: 10px; text-align: center;">$codigo</h1>
        </div>
      """;

    try {
      print('🚀 Enviando e-mail real para $emailDestino...');
      await send(message, smtpServer);
      print('✅ SUCESSO: E-mail enviado!');
      return true;
    } on MailerException catch (e) {
      print('❌ ERRO DO GOOGLE: ${e.message}');
      return false;
    } catch (e) {
      print('❌ ERRO DESCONHECIDO: $e');
      return false;
    } finally {
      print('--- [DEBUG EMAIL_SERVICE] FIM ---');
    }
  }
}
