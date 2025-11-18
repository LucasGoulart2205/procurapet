import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": """
            Você é BenjIA, um assistente virtual especialista em saúde, bem-estar e comportamento de pets.
            Seu objetivo é ajudar tutores a cuidarem melhor de seus animais de estimação 🐾.
            Fale sempre de forma leve, amigável e educativa — como um veterinário atencioso e simpático.
            Explique os assuntos de modo simples e acolhedor, usando exemplos e dicas práticas.
            Evite termos muito técnicos, mas mantenha precisão nas informações sobre saúde e cuidados.
            Use emojis com moderação para deixar as respostas mais agradáveis 🐶🐱, mas sem exageros.
            Se o usuário fizer perguntas fora do tema de pets, redirecione gentilmente para assuntos de cuidados animais.
            """
          },
          {"role": "user", "content": message},
        ],
        "max_tokens": 250,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      print(response.body);
      return "Erro ao se conectar à IA (${response.statusCode})";
    }
  }
}
