import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:pdf_text/pdf_text.dart';
import 'package:pdf_render/pdf_render.dart';



class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _pdfPath = '';
  bool _pdfReady = false;
  Key _pdfViewKey = UniqueKey();
  final firebaseStorage = FirebaseStorage.instance;
  final firestore = FirebaseFirestore.instance;
  // final firebaseStorage = FirebaseStorage.instanceFor(bucket: 'gs://your-default-bucket-url');


  Future<Uint8List> readFileAsBytes(File file) async {
    final byteData = await file.readAsBytes();
    return byteData.buffer.asUint8List();
  }


  // Future<List<String>> extractTextFromPdfAndConvertToKeywords(File pdfFile) async {
  //   List<String> keywords = [];
  //
  //   try {
  //     PDFDoc doc = await PDFDoc.fromFile(pdfFile);
  //     String text = await doc.text;
  //
  //     // Extract words from the text and remove duplicates
  //     keywords = text.split(RegExp(r'\W+')).toSet().toList();
  //
  //   } catch (e) {
  //     print('Error extracting keywords from PDF: $e');
  //   }
  //
  //   return keywords;
  // }


  Future<Map<String, List<String>>> extractTextFromPdfAndConvertToKeywords(File pdfFile) async {
    List<String> keywords = [];
    List<String> sentences = [];

    try {
      PDFDoc doc = await PDFDoc.fromFile(pdfFile);
      String text = await doc.text;

      // Extract words from the text and remove duplicates
      keywords = text.split(RegExp(r'\W+')).toSet().toList();

      // Extract sentences from the text
      sentences = text.split(RegExp(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)\s'));

    } catch (e) {
      print('Error extracting keywords and sentences from PDF: $e');
    }

    return {
      'keywords': keywords,
      'sentences': sentences,
    };
  }






  Future<void> uploadPdfToFirebaseStorageAndSaveToFirestore(File pdfFile) async {
    try {

      // Extract keywords from the PDF
      Map<String, List<String>> extractedData = await extractTextFromPdfAndConvertToKeywords(pdfFile);
      List<String> keywords = extractedData['keywords'] ?? [];
      List<String> sentences = extractedData['sentences'] ?? [];


      // Define the storage path
      String storagePath = 'pdfFiles/${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Get the content of the file as Uint8List
      Uint8List fileContent = await readFileAsBytes(pdfFile);

      // Upload the PDF file to Firebase Storage
      final uploadTask = firebaseStorage.ref(storagePath).putData(fileContent);

      // Get the uploaded file's download URL
      final downloadUrl = await (await uploadTask).ref.getDownloadURL();

      // Get the number of pages in the PDF
      final pdfDocument = await PdfDocument.openFile(pdfFile.path);
      int numberOfPages = pdfDocument.pageCount;

      // Get the size of the PDF
      int pdfSize = pdfFile.lengthSync();

      // Save the metadata to Firestore
      DocumentReference docRef = await firestore.collection('pdfFiles').add({
        'url': downloadUrl,
        'name': pdfFile.path.split('/').last,
        'uploadedAt': FieldValue.serverTimestamp(),
        'numberOfPages': numberOfPages,
        'size': pdfSize,
        'keywords': keywords,// Add the keywords field
        'sentences': sentences, // Add the sentences field
        'storagePath': storagePath,
      });

      print('PDF uploaded and metadata saved to Firestore');

      // Get the ID of the PDF
      String pdfId = docRef.id;
      print('PDF ID: $pdfId');

    } catch (e) {
      print('Error uploading PDF and saving to Firestore: $e');
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: _pdfReady
            ? PDFView(
          key: _pdfViewKey,
          filePath: _pdfPath,
        )
            : Center(
          child: Text('No PDF selected'),
        ),
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
                  _pdfViewKey = UniqueKey(); // Update the key
                });

                // Upload the PDF file and save its download URL in Firestore
                uploadPdfToFirebaseStorageAndSaveToFirestore(File(_pdfPath));

              }
            },
            child: Icon(Icons.upload_file),
            tooltip: 'Upload PDF',
          ),

        ],
      ),
    );
  }
}
