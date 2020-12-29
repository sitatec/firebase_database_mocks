import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

class UserRepository {
  UserRepository(this.firebaseDatabase);
  FirebaseDatabase firebaseDatabase;

  Future<String> getUserName(String userId) async {
    final userNode =
        firebaseDatabase.reference().child('users').child('$userId/name');
    final dataSnapshot = await userNode.once();
    return dataSnapshot.value;
  }
}

void main() {
  FirebaseDatabase firebaseDatabase;
  UserRepository userRepository;
  // Put fake data
  const userId = 'userId';
  const userName = 'Elon musk';
  MockFirebaseDatabase.instance
      .reference()
      .child('users')
      .child(userId)
      .child('name')
      .set(userName);
  setUp(() {
    firebaseDatabase = MockFirebaseDatabase.instance;
    userRepository = UserRepository(firebaseDatabase);
  });
  test('Should contain value', () async {
    final userNameFromFakeDatabase = userRepository.getUserName(userId);
    expect(userNameFromFakeDatabase, equals(userName));
  });
}
