import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';

class MockDataSnapshot extends Mock implements DataSnapshot {
  final DatabaseReference _ref;
  final dynamic _value;

  MockDataSnapshot(this._ref, this._value);

  @override
  String? get key => _ref.key;

  @override
  DatabaseReference get ref => _ref;

  @override
  dynamic get value => _value;

  @override
  bool get exists => _value != null;
}
