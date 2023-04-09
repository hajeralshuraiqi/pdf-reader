import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';



class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _pdfPath = '';
  bool _pdfReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: _pdfReady
          ? PDFView(
        filePath: _pdfPath,
      )
          : Center(
        child: Text('No PDF selected'),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result != null) {
                setState(() {
                  _pdfPath = result.files.single.path!;
                  _pdfReady = true;
                });
              }
            },
            child: Icon(Icons.upload_file),
            tooltip: 'Upload PDF',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              // Implement saving the PDF file here
            },
            child: Icon(Icons.save),
            tooltip: 'Save PDF',
          ),
        ],
      ),
    );
  }
}
