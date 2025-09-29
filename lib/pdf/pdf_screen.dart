import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/utils.dart';

class ShowPDF extends StatefulWidget {
  final String? title;
  final File? pdf;

  const ShowPDF({super.key, this.pdf, this.title});

  @override
  State<ShowPDF> createState() => _ShowPDFState();
}

class _ShowPDFState extends State<ShowPDF> with WidgetsBindingObserver {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Utils.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title!),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share),
            // onPressed: () {
            //   SharePlus.instance.share(
            //     ShareParams(
            //       text: widget.title,
            //       files: [XFile(widget.pdf!.path)],
            //     ),
            //   );
            // },
            onPressed: () {
              if (Platform.isWindows) {
                openPdf(widget.pdf!.path);
              } else {
                SharePlus.instance.share(
                  ShareParams(
                    text: widget.title,
                    files: [XFile(widget.pdf!.path)],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          SfPdfViewer.file(File(widget.pdf!.path)),
        ],
      ),
    );
  }

  void openPdf(String path) async {
    final fileUri = Uri.file(path);
    if (await canLaunchUrl(fileUri)) {
      await launchUrl(fileUri);
    } else {
      throw 'Could not launch $path';
    }
  }
}
