import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../widgets/universal_navigation.dart';

String _transcriptionWsUrl() {
  return 'wss://api-gateway-1070008536698.europe-north1.run.app/ws';
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  WebSocketChannel? _transcriptionChannel;

  bool _isRecording = false;
  List<int> _pcmBuffer = [];
  Stream<Uint8List>? _audioStream;

  String _transcription = "No recording yet...";
  String _summarisation = "No summarisation yet...";

  @override
  void dispose() {
    if (_isRecording) {
      _stopRecording();
    }
    _audioRecorder.dispose();
    _transcriptionChannel?.sink.close();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      setState(() {
        _transcription = "Recording in progress...";
        _summarisation = "No summarisation yet...";
      });
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || !await _audioRecorder.hasPermission()) return;

    _transcriptionChannel = WebSocketChannel.connect(
      Uri.parse(_transcriptionWsUrl()),
    );
    _transcriptionChannel!.stream.listen(
      (message) {
        try {
          final jsonData = jsonDecode(message);
          final text = jsonData['transcription'];
          final summary = jsonData['report'];

          setState(() {
            _transcription = text ?? _transcription;
            _summarisation = summary ?? _summarisation;
          });
        } catch (_) {
          setState(() {
            if (_transcription == "No recording yet..." ||
                _transcription.startsWith("Recording in progress")) {
              _transcription = message;
            } else {
              _transcription = "$_transcription $message";
            }
          });
        }
      },
      onError: (error) => debugPrint("Transcription WS error: $error"),
      onDone: () => debugPrint("Transcription WS closed."),
    );

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    );

    _pcmBuffer.clear();
    _audioStream = await _audioRecorder.startStream(config);
    _audioStream?.listen(
      (chunk) {
        _pcmBuffer.addAll(chunk);
        _transcriptionChannel?.sink.add(chunk);
      },
      onError: (err) => debugPrint("Audio stream error: $err"),
      onDone: () => debugPrint("Audio stream done."),
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    await _transcriptionChannel?.sink.close();
    _transcriptionChannel = null;
    setState(() => _isRecording = false);

    // Removed upload functionality: the buffered audio data is no longer used.
    _pcmBuffer.clear();
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const UniversalNavigation(
        currentIndex: 0,
        pageTitle: 'DEEPSPEAK',
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Tap the microphone icon to record. When done, the recording will be transcribed and summarized. The transcription and summary will be displayed below.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: _isRecording ? 80 : 100,
                  height: _isRecording ? 80 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _isRecording
                            ? Colors.deepPurple
                            : Colors.deepPurple.shade200,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildResultCard("Transcription", _transcription),
                    _buildResultCard("Summarisation", _summarisation),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.deepPurple),
                  onPressed: () => _copyToClipboard(content),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
