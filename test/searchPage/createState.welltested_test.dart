import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdfreader/lib/searchPage.dart';
import 'package:pdfreader/searchPage.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

void main() {
  group('SearchPageState', () {
    late SearchPageState searchPageState;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockFirebaseStorage mockFirebaseStorage;

    setUp(() {
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockFirebaseStorage = MockFirebaseStorage();
      searchPageState = SearchPageState();
      searchPageState._searchController.text = 'test';
    });

    test('createState returns SearchPageState', () {
      expect(searchPageState.createState(), isA<SearchPageState>());
    });

    test('searchPdfFiles returns list of maps', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();
      final List<Map<String, dynamic>> expectedSearchResults = [
        {
          'doc': mockQueryDocumentSnapshot,
          'sentences': ['test sentence']
        }
      ];

      when(mockFirebaseFirestore.collection('pdfFiles'))
          .thenReturn(MockCollectionReference());
      when(MockCollectionReference().where('keywords', arrayContains: 'test'))
          .thenReturn(MockQuery());
      when(MockQuery().get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot['sentences'])
          .thenReturn(['test sentence']);

      final searchResults = await searchPageState._searchPdfFiles('test');

      expect(searchResults, expectedSearchResults);
    });

    test('deletePdfFile shows dialog on successful deletion', () async {
      final mockBuildContext = MockBuildContext();
      final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();
      final mockReference = MockReference();

      when(mockFirebaseStorage.ref('test')).thenReturn(mockReference);
      when(mockReference.delete()).thenAnswer((_) async => null);
      when(mockFirebaseFirestore.collection('pdfFiles'))
          .thenReturn(MockCollectionReference());
      when(MockCollectionReference().doc('test'))
          .thenReturn(MockDocumentReference());
      when(MockDocumentReference().delete()).thenAnswer((_) async => null);
      when(mockBuildContext).thenReturn(MockBuildContext());

      await searchPageState._deletePdfFile(mockBuildContext, 'test', 'test');

      verify(mockBuildContext.showDialog(
        context: anyNamed('context'),
        builder: anyNamed('builder'),
      ));
    });

    test('deletePdfFile throws error on unsuccessful deletion', () async {
      final mockBuildContext = MockBuildContext();
      final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();
      final mockReference = MockReference();

      when(mockFirebaseStorage.ref('test')).thenReturn(mockReference);
      when(mockReference.delete()).thenThrow(Exception());
      when(mockFirebaseFirestore.collection('pdfFiles'))
          .thenReturn(MockCollectionReference());
      when(MockCollectionReference().doc('test'))
          .thenReturn(MockDocumentReference());
      when(MockDocumentReference().delete()).thenAnswer((_) async => null);
      when(mockBuildContext).thenReturn(MockBuildContext());

      expect(
        () async => await searchPageState._deletePdfFile(
            mockBuildContext, 'test', 'test'),
        throwsA(isInstanceOf<Exception>()),
      );
    });
  });
}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockQuery extends Mock implements Query {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockBuildContext extends Mock implements BuildContext {}
