import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../widgets/ui.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final stt = SpeechToText();
  final tts = FlutterTts();
  String _text = '';
  bool _listening = false;

  Future<void> _listen() async {
    final available = await stt.initialize();
    if (!available) {
      setState(() => _text = 'Speech recognition unavailable');
      return;
    }
    setState(() => _listening = true);
    stt.listen(onResult: (r) => setState(() => _text = r.recognizedWords));
  }

  Future<void> _stop() async {
    await stt.stop();
    setState(() => _listening = false);
  }

  Future<void> _speak() async {
    await tts.speak(_text.isEmpty ? 'Hello' : _text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar('Voice'),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(_text),
        const SizedBox(height: 16),
        Row(children: [
          ElevatedButton(onPressed: _listening ? _stop : _listen, child: Text(_listening ? 'Stop' : 'Listen')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _speak, child: const Text('Speak')),
        ]),
        const SizedBox(height: 12),
        const Text('Voice is optional. App works without it.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
    );
  }
}
