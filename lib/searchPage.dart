import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:welltested/annotation.dart';


@Welltested()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
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
    // print("Storage path: $storagePath"); // Add this line to print the storage path

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
            title: const Text('File Deleted'),
            content: const Text('The file has been deleted successfully.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // print("Error deleting file: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 100.0, right: 20, left: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Enter keyword',
                prefixIcon: Icon(Icons.search, color: Color(0xFFD31010)), // Set the icon color to #D31010
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25.0),
                  ),
                  borderSide: BorderSide(color: Color(0xFFD31010)), // Set the border color to #D31010
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25.0),
                  ),
                  borderSide: BorderSide(color: Color(0xFFD31010)), // Set the border color to #D31010 when focused
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                });
              },
            ),
            // SizedBox(height: 10.0),
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height - 200, // Adjust the height as per your needs
                child: _searchKeyword.isEmpty
                    ? const Center(child: Text('Enter a keyword to search'))
                    : FutureBuilder<List<Map<String, dynamic>>>(
                  future: _searchPdfFiles(_searchKeyword),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                            // print('Storage path not found for document $pdfDocId');
                            return const SizedBox.shrink(); // Render an empty widget if the storage path is not found
                          }

                          return
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0), // Set the desired border radius
                              ),
                              elevation: 2, // Add a subtle elevation to the card
                              color: Colors.grey[200], // Set the desired background color
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0), // set a padding for ListTile
                                    child: ListTile(
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: 'PDF Name: ', // Add index + 1 to display the number
                                                  style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xFFD31010)),
                                                ),
                                                TextSpan(
                                                  text: '$pdfName\n',
                                                  style: DefaultTextStyle.of(context).style,
                                                ),
                                                const TextSpan(
                                                  text: 'PDF ID: ',
                                                  style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xFFD31010)),
                                                ),
                                                TextSpan(
                                                  text: '$pdfDocId)',
                                                  style: DefaultTextStyle.of(context).style,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          const Text(
                                            'Sentences containing this keyword:',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD31010)),
                                          ),
                                          const SizedBox(height: 4.0),
                                          for (String sentence in sentences) Text('- $sentence'),
                                          const SizedBox(height: 50.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0, // Position at the bottom
                                    right: 0, // Position at the right
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0), // Add padding if needed
                                      child: InkWell(
                                        onTap: () async {
                                          await _deletePdfFile(context, pdfDocId, storagePath);
                                          setState(() {
                                            // Refresh the list after deleting the PDF
                                          });
                                        },
                                        child: Container(
                                          width: 30, // specify the width
                                          height: 30, // specify the height
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD31010), // specify the color here
                                            shape: BoxShape.circle, // this will make it circular
                                          ),
                                          child: const Icon(Icons.delete, color: Colors.white,size: 17,), // Change the color of icon to contrast with background
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}


