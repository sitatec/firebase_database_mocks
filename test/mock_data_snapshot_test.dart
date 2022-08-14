import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/src/mock_data_snapshot.dart';
import 'package:firebase_database_mocks/src/mock_database_reference.dart';
import 'package:firebase_database_mocks/src/set_up_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDatabaseReference databaseReference;
  late DatabaseReference reference;
  setUp(() {
    setupFirebaseMocks();
    databaseReference = MockDatabaseReference();
    reference = databaseReference.child('foo/bar');
  });

  test('Should return reference that was used for creation', () {
    expect(MockDataSnapshot(reference, null).ref, equals(reference));
  });

  test('Should return key that is the same as in reference', () {
    expect(MockDataSnapshot(reference, null).key, equals(reference.key));
  });
}