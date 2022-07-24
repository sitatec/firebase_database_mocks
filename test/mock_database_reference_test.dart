import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:firebase_database_mocks/src/mock_database_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDatabaseReference databaseReference;
  setUp(() {
    setupFirebaseMocks(); // Just to make sure it that no exception is thrown.
    databaseReference = MockDatabaseReference();
  });

  group('Node path handling : ', () {
    test("Should get a reference with a initial path", () {
      expect(
        MockFirebaseDatabase.instance.ref("initialPath").path,
        MockDatabaseReference().child("initialPath").path,
      );
    });
    test("Should get reference using the deprecated reference() method", () {
      expect(
        MockFirebaseDatabase.instance.reference().child("deprecated").path,
        MockDatabaseReference().child("deprecated").path,
      );
    });
    test('Should work with slash as prefix', () {
      expect(
        databaseReference.child('/test').path,
        equals(MockDatabaseReference().child('test').path),
      );
    });
    test('Should work with slash as suffix', () {
      expect(
        databaseReference.child('test/').path,
        equals(MockDatabaseReference().child('test').path),
      );
    });
    test('Should work with slash as suffix', () {
      expect(
        databaseReference.child('/test/').path,
        equals(MockDatabaseReference().child('test').path),
      );
    });
    test('Should work with nested nodes', () {
      expect(
        databaseReference.child('test').child('other').path,
        equals(MockDatabaseReference().child('test/other').path),
      );
      expect(
        databaseReference
            .child('path')
            .child('mock')
            .child('test')
            .child('other')
            .path,
        equals(MockDatabaseReference().child('path/mock/test/other').path),
      );
    });
    test('Should return null when a nonexistent path is given', () async {
      expect(
        (await databaseReference.child('fghgg').once()).snapshot.value,
        isNull,
      );
      expect(
        (await databaseReference.child('o_/therèè_/Test').once())
            .snapshot
            .value,
        isNull,
      );
    });

    group('Should return null when a nonexistent path that', () {
      test('starts with existent node path is given', () async {
        await databaseReference.child('existing_path').set('snapshot.value');
        expect(
          (await databaseReference.child('existing_path/therèè_/Test').once())
              .snapshot
              .value,
          isNull,
        );
      });
      test('wrap existent node path is given', () async {
        await databaseReference.child('existing_path').set('snapshot.value');
        expect(
          (await databaseReference.child('any/existing_path/thè_/Tt').once())
              .snapshot
              .value,
          isNull,
        );
        await databaseReference
            .child('tteesstt')
            .set({'key': 'snapshot.value'});
        expect(
          (await databaseReference.child('tttttst/path/tteesstt/Test').once())
              .snapshot
              .value,
          isNull,
          reason: 'With Map as snapshot.value',
        );
      });
      test('end with existent node path is given', () async {
        await databaseReference.child('end').set('snapshot.value');
        expect(
          (await databaseReference.child('any/existing_path/Test/end').once())
              .snapshot
              .value,
          isNull,
        );
      });

      // Todo put any expect satement inside test function.
    });

    // test('Should work when wrapped in two slash or more', () {
    //   expect(
    //     databaseReference.child('//test//').path,
    //     equals(MockDatabaseReference().child('test').path),
    //   );
    //   expect(
    //     databaseReference.child('//test///').path,
    //     equals(MockDatabaseReference().child('test').path),
    //   );
    // });
  });
  group('Work with any type of data : ', () {
    test('Should set String', () async {
      await databaseReference.child('test').set('snapshot.value');
      expect(
        (await databaseReference.child('test').once()).snapshot.value,
        equals('snapshot.value'),
      );
      await databaseReference.child('otherTest/test').set('otherValue');
      expect(
        (await databaseReference.child('otherTest/test').once()).snapshot.value,
        equals('otherValue'),
      );
    });

    test('Should set data in nested nodes', () async {
      databaseReference
          .child('path_')
          .child('mock_')
          .child('test_')
          .child('other_')
          .set("NESTED");

      expect(
        (await databaseReference
                .child('path_')
                .child('mock_')
                .child('test_')
                .child('other_')
                .once())
            .snapshot
            .value,
        equals("NESTED"),
      );
      expect(
        (await databaseReference.child('path_/mock_/test_/other_').once())
            .snapshot
            .value,
        equals("NESTED"),
      );
    });

    test('Should set Map', () async {
      await databaseReference.child('test').set({'key': 'snapshot.value'});
      expect((await databaseReference.child('test').once()).snapshot.value,
          equals({'key': 'snapshot.value'}));
    });

    test(
        'Should get nested Map even if the keys of maps was not set individually',
        () async {
      const nestedMap = {
        'key': {
          'nkey1': 'value1',
          'nkey2': {'otheNkey': 'nestedValue'}
        }
      };
      await databaseReference.child('tes').set(nestedMap);
      expect((await databaseReference.child('tes').once()).snapshot.value,
          equals(nestedMap));

      expect(
          (await databaseReference.child('tes/key').once()).snapshot.value,
          equals({
            'nkey1': 'value1',
            'nkey2': {'otheNkey': 'nestedValue'}
          }));

      expect(
          (await databaseReference.child('tes/key/nkey1').once())
              .snapshot
              .value,
          equals('value1'));

      expect(
          (await databaseReference.child('tes/key/nkey2').once())
              .snapshot
              .value,
          equals({'otheNkey': 'nestedValue'}));
    });
  });

  // group('Set data at any node reference :', null);

  group('Data persistence : ', () {
    tearDown(() {
      MockFirebaseDatabase.setDataPersistanceEnabled(ennabled: true);
    });

    test('Should persist data while test running', () async {
      MockFirebaseDatabase.setDataPersistanceEnabled(ennabled: true);
      MockDatabaseReference? _databaseReference = MockDatabaseReference();
      await _databaseReference.child('test1').set('value1');
      await _databaseReference.child('test2/test2').set('value2');
      await _databaseReference.child('test1/test_one').set('value3');
      _databaseReference = null;
      expect(_databaseReference, isNull);

      var newDatabaseReference = MockDatabaseReference();
      expect(
        (await newDatabaseReference.child('test1').once()).snapshot.value,
        equals('value1'),
      );
      print('test1 passed');
      expect(
        (await newDatabaseReference.child('test2/test2').once()).snapshot.value,
        equals('value2'),
      );
      expect(
        (await newDatabaseReference.child('test1/test_one').once())
            .snapshot
            .value,
        equals('value3'),
      );
    });
    test('Should not persist data', () async {
      MockFirebaseDatabase.setDataPersistanceEnabled(ennabled: false);
      await databaseReference.child('test_').set('snapshot.value');
      expect(
        (await databaseReference.child('test_').once()).snapshot.value,
        equals('snapshot.value'),
      );
      await databaseReference.child('otherTest_/test').set('otherValue');
      expect(
        (await databaseReference.child('otherTest_/test').once())
            .snapshot
            .value,
        equals('otherValue'),
      );
      expect(
          (await MockDatabaseReference().child('test_').once()).snapshot.value,
          isNull);
    });
  });

  test('Should return a stream of data', () async {
    await databaseReference.child('streamTest').set('StreamVal');
    final stream = databaseReference.child('streamTest').onValue;
    expect((await stream.first).snapshot.value, equals('StreamVal'));
  });

  // Todo implement all dataSnapshot, dbReference and fbDatabase getters and setters if possible.

  // test(
  //     'Should not persist data if setting "persistData" of MockFirebaseData is false',
  //     () async {
  //   MockFirebaseDatabase.settings(persistData: false);
  //   var databaseReference = MockDatabaseReference();
  //   var test = databaseReference.child('test1');
  //   await test.set('value1');
  //   await databaseReference.child('test2/test2').set('value2');
  //   await databaseReference.child('test1/test_one').set('value3');
  //   expect(
  //     (await test.once()).snapshot.value,
  //     equals('value1'),
  //   );
  //   databaseReference = null;
  //   expect(databaseReference, isNull);

  //   var newDatabaseReference = MockDatabaseReference();
  //   expect(
  //     (await newDatabaseReference.child('test1').once()).snapshot.value,
  //     isNull,
  //   );
  //   expect(
  //     (await newDatabaseReference.child('test2/test2').once()).snapshot.value,
  //     isNull,
  //   );
  //   expect(
  //     (await newDatabaseReference.child('test1/test_one').once()).snapshot.value,
  //     isNull,
  //   );
  // });
}
