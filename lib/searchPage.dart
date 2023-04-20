import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';



class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  Future<List<Map<String, dynamic>>> _searchPdfFiles(String keyword) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('pdfFiles')
        .where('keywords', arrayContains: keyword)
        .get();

    List<Map<String, dynamic>> searchResults = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      // Extract the list of sentences from the 'sentences' field
      List<String> sentences = List<String>.from(doc['sentences']);

      // Filter the sentences to only include those containing the keyword
      List<String> matchingSentences =
      sentences.where((sentence) => sentence.contains(keyword)).toList();

      // Add the document and the matching sentences to the search results
      searchResults.add({
        'doc': doc,
        'sentences': matchingSentences,
      });
    }

    return searchResults;
  }



  Future<void> _deletePdfFile(BuildContext context, String docId, String storagePath) async {
    print("Storage path: $storagePath"); // Add this line to print the storage path

    try {
      // Delete the PDF file from Firebase Storage
      await FirebaseStorage.instance.ref(storagePath).delete();

      // Remove the metadata from Firestore
      await FirebaseFirestore.instance.collection('pdfFiles').doc(docId).delete();

      // Show an alert dialog to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('File Deleted'),
            content: Text('The file has been deleted successfully.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error deleting file: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search keyword',
                  hintText: 'Enter keyword',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              _searchKeyword.isEmpty
                  ? Text('Enter a keyword to search')
                  : FutureBuilder<List<Map<String, dynamic>>>(
                future: _searchPdfFiles(_searchKeyword),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<Map<String, dynamic>> searchResults = snapshot.data ?? [];
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        QueryDocumentSnapshot doc = searchResults[index]['doc'];
                        List<String> sentences = searchResults[index]['sentences'];
                        String pdfName = doc['name'];
                        String pdfDocId = doc.id;
                        String? storagePath = (doc.data() as Map<String, dynamic>).containsKey('storagePath')
                            ? doc['storagePath']
                            : null;

                        if (storagePath == null) {
                          print('Storage path not found for document $pdfDocId');
                          return SizedBox.shrink(); // Render an empty widget if the storage path is not found
                        }

                        return ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${index + 1}.PDF Name: ', // Add index + 1 to display the number
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    TextSpan(
                                      text: '$pdfName\n',
                                      style: DefaultTextStyle.of(context).style,
                                    ),
                                    TextSpan(
                                      text: 'PDF ID: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    TextSpan(
                                      text: '$pdfDocId)',
                                      style: DefaultTextStyle.of(context).style,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 8.0),
                              Text('Sentences containing this keyword:',style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              SizedBox(height: 4.0),
                              for (String sentence in sentences) Text('- $sentence'),
                              SizedBox(height: 50.0),
                            ],

                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await _deletePdfFile(context,pdfDocId, storagePath);
                              setState(() {
                                // Refresh the list after deleting the PDF
                              });
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}


