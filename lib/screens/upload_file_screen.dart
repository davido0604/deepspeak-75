import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../widgets/universal_navigation.dart';

/// Production endpoint now points to your new tested URL.
/// For non-production, it falls back to localhost settings.
String _uploadUrl() {
  if (kReleaseMode) {
    // Use the new tested URL.
    return 'https://api-gateway-1070008536698.europe-north1.run.app/upload';
  }
  if (kIsWeb) {
    return 'https://api-gateway-1070008536698.europe-north1.run.app/upload';
  } else if (Platform.isAndroid) {
    return 'https://api-gateway-1070008536698.europe-north1.run.app/upload';
  } else if (Platform.isIOS) {
    return 'https://api-gateway-1070008536698.europe-north1.run.app/upload';
  }
  return 'https://api-gateway-1070008536698.europe-north1.run.app/upload';
}

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  bool _isUploading = false;
  // The full texts from the backend.
  String _fullTranscription = "";
  String _fullReport = "No summarisation yet...";
  // The animated (printed) texts.
  String _printedTranscription = "";
  String _printedReport = "";

  Timer? _transcriptionTimer;
  Timer? _reportTimer;

  // WebSocket channel for real-time streaming.
  late final WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    // Connect to the WebSocket endpoint.
    _channel = WebSocketChannel.connect(
      Uri.parse("wss://api-gateway-1070008536698.europe-north1.run.app/upload"),
    );
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'transcription') {
        debugPrint("Real-time transcription: ${data['text']}");
        setState(() {
          // Append the real-time transcription text.
          _printedTranscription += " " + data['text'];
        });
      } else if (data['type'] == 'final') {
        debugPrint("Final transcription: ${data['transcription']}");
        debugPrint("Classification: ${data['classification']}");
        debugPrint("Generated report: ${data['report']}");
        setState(() {
          _fullReport = data['report'];
          // Optionally, if you want a printing animation for report as well,
          // you could call _animateReport(_fullReport) here.
        });
      }
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _transcriptionTimer?.cancel();
    _reportTimer?.cancel();
    super.dispose();
  }

  /// Initiates file picking, uploads the file, and processes transcript/report.
  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true;
      // Clear previous results when starting a new upload.
      _fullTranscription = "";
      _printedTranscription = "";
      _fullReport = "No report generated yet...";
      _printedReport = "";
    });

    // Pick an audio file.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result == null || result.files.isEmpty) {
      setState(() => _isUploading = false);
      return;
    }
    final fileBytes = result.files.first.bytes;
    final fileName = result.files.first.name;
    if (fileBytes == null) {
      setState(() => _isUploading = false);
      return;
    }

    // Debug: Print file details.
    debugPrint("Uploading file: $fileName");

    // Upload to the /upload endpoint.
    try {
      var uri = Uri.parse(_uploadUrl());
      debugPrint("Calling URL: $uri");

      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );
      var streamedResponse = await request.send();
      var statusCode = streamedResponse.statusCode;
      debugPrint("Response status code: $statusCode");

      if (statusCode == 200) {
        var respStr = await streamedResponse.stream.bytesToString();
        debugPrint("Raw response: $respStr");
        var data = jsonDecode(respStr);

        setState(() {
          _fullTranscription = data["transcription"] ?? "";
          _fullReport = data["report"] ?? "No report generated yet...";
        });
        // Optionally start printing the transcription from the file upload response.
        _animateTranscription(_fullTranscription);
      } else {
        setState(() {
          _fullTranscription = "";
          _printedTranscription = "";
          _fullReport = "Upload error: $statusCode";
          _printedReport = "";
        });
      }
    } catch (e) {
      debugPrint("Upload exception: $e");
      setState(() {
        _fullTranscription = "";
        _printedTranscription = "";
        _fullReport = "Upload error: $e";
        _printedReport = "";
      });
    }

    setState(() {
      _isUploading = false;
    });
  }

  /// Animates printing effect for transcription.
  void _animateTranscription(String fullText) {
    _transcriptionTimer?.cancel();
    _printedTranscription = "";
    int currentIndex = 0;
    const duration = Duration(milliseconds: 50);
    _transcriptionTimer = Timer.periodic(duration, (timer) {
      if (currentIndex < fullText.length) {
        setState(() {
          _printedTranscription += fullText[currentIndex];
        });
        currentIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  /// Animates printing effect for report.
  void _animateReport(String fullText) {
    _reportTimer?.cancel();
    _printedReport = "";
    int currentIndex = 0;
    const duration = Duration(milliseconds: 50);
    _reportTimer = Timer.periodic(duration, (timer) {
      if (currentIndex < fullText.length) {
        setState(() {
          _printedReport += fullText[currentIndex];
        });
        currentIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  /// Generates a PDF from provided title and content and triggers a share/print dialog.
  Future<void> _downloadPdf(String title, String content) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(content, style: pw.TextStyle(fontSize: 16)),
              ],
            ),
      ),
    );
    // This will open a share/print dialog on supported platforms.
    await Printing.sharePdf(bytes: await pdf.save(), filename: '$title.pdf');
  }

  /// Builds a scrollable widget for the transcription portion.
  Widget _buildFileTranscriptWidget() {
    if (_printedTranscription.isEmpty) {
      return const Text(
        "No file uploaded yet...",
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      );
    }
    // Using a single block for transcription.
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7FF),
        borderRadius: BorderRadius.circular(5),
        border: Border(
          left: BorderSide(width: 4, color: const Color(0xFF1890FF)),
        ),
      ),
      child: Text(
        "Transcription: $_printedTranscription",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  /// Builds a scrollable widget for the report portion.
  Widget _buildFileReportWidget() {
    if (_printedReport.isEmpty) {
      return const Text(
        "Press 'Generate Rapport' to see the report.",
        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      _printedReport,
      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
    );
  }

  /// Copies the given text to clipboard.
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
  }

  /// Returns the full transcription text (for copying).
  String _getTranscriptText() {
    return _printedTranscription;
  }

  @override
  Widget build(BuildContext context) {
    // Button size for the big circle icon.
    final double buttonSize = 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const UniversalNavigation(
        currentIndex: 1,
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
                  "Tap the file icon and pick an audio file. When done, the recording will be transcribed and summarized. The transcription and report will be displayed below.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 24),
              // Big circular button for file upload.
              Container(
                width: buttonSize * 2,
                height: buttonSize * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isUploading
                          ? Colors.deepPurple
                          : Colors.deepPurple.shade200,
                ),
                child: GestureDetector(
                  onTap: _isUploading ? null : _uploadFile,
                  child: Icon(
                    _isUploading ? Icons.hourglass_empty : Icons.folder_open,
                    size: buttonSize,
                    color: _isUploading ? Colors.white : Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Two side-by-side boxes: Transcription and Report.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transcription Box.
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        maxHeight: 400,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with copy and download as PDF buttons.
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Transcription",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          color: Colors.deepPurple,
                                        ),
                                        onPressed:
                                            () => _copyToClipboard(
                                              _getTranscriptText(),
                                            ),
                                        tooltip: "Copy transcription",
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          color: Colors.deepPurple,
                                        ),
                                        onPressed:
                                            () => _downloadPdf(
                                              "Transcription",
                                              _printedTranscription,
                                            ),
                                        tooltip: "Download as PDF",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _isUploading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _buildFileTranscriptWidget(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Report Box.
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        maxHeight: 400,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with copy, download as PDF and Generate Rapport buttons.
                              Row(
                                children: [
                                  const Text(
                                    "Report",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      // Start the report printing animation.
                                      _animateReport(_fullReport);
                                    },
                                    child: const Text("Generate Rapport"),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.copy,
                                      color: Colors.deepPurple,
                                    ),
                                    onPressed:
                                        () => _copyToClipboard(_printedReport),
                                    tooltip: "Copy report",
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.download,
                                      color: Colors.deepPurple,
                                    ),
                                    onPressed:
                                        () => _downloadPdf(
                                          "Report",
                                          _printedReport,
                                        ),
                                    tooltip: "Download as PDF",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _isUploading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _buildFileReportWidget(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
