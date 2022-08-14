import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database_mocks/src/mock_database_event.dart';
import 'package:mockito/mockito.dart';

import 'mock_data_snapshot.dart';
import 'mock_firebase_database.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {
  var _nodePath = '/';

  // ignore: prefer_final_fields
  static Map<String, dynamic>? _persistedData = <String, dynamic>{};
  Map<String, dynamic>? _volatileData = <String, dynamic>{};

  MockDatabaseReference();

  MockDatabaseReference._(nodePath, [this._volatileData]) {
    _nodePath += nodePath;
  }

  /// TODO implement real [onchange] (should yield each change).
  Stream<DatabaseEvent> get onValue async* {
    yield await once();
  }

  Map<String, dynamic>? get _data {
    if (MockFirebaseDatabase.persistData) {
      return _persistedData;
    }
    return _volatileData;
  }

  set _data(data) {
    if (MockFirebaseDatabase.persistData) {
      _persistedData = data;
    } else
      return _volatileData = data;
  }

  @override
  String? get key {
    if (_nodePath == '/') {
      return null;
    }
    return _nodePath.substring(1, _nodePath.length - 1).split('/').last;
  }

  @override
  String get path => _nodePath;

  @override
  DatabaseReference child(String path) {
    if (!path.endsWith('/')) path += '/';
    path = (_nodePath + path).replaceAll(RegExp(r'^/+'), '');
    return MockDatabaseReference._(
      path,
      _data,
    );
  }

  @override
  Future<void> set(dynamic value, {dynamic priority}) async {
    if (_nodePath == '/') {
      _data = value;
    } else {
      var nodePathWithoutSlashesAtEndAndStart =
          _nodePath.substring(1, _nodePath.length - 1);
      var nodesList = nodePathWithoutSlashesAtEndAndStart.split('/');
      Map<String, dynamic>? tempData = <String, dynamic>{};
      Map<String, dynamic>? lastNodeInCurrentData;
      var nodeIndexReference = _Int(0);
      if (_data![nodesList.first] == null) {
        lastNodeInCurrentData = _data;
      } else {
        lastNodeInCurrentData = _getNextNodeData(
            data: _data, nodesList: nodesList, nodeIndex: nodeIndexReference);
      }
      var nodeIndex = nodeIndexReference.value;
      var noNewNodeToAdd = nodesList.length <= nodeIndex;
      if (noNewNodeToAdd) {
        lastNodeInCurrentData![nodesList.last] = value;
      } else {
        var firstNodeInNewData = nodesList[nodeIndex++];
        if (nodeIndex < nodesList.length) {
          tempData = _buildNewNodesTree(
            nodeIndex: nodeIndex,
            nodesList: nodesList,
            data: tempData,
            value: value,
          );
          lastNodeInCurrentData!.addAll({firstNodeInNewData: tempData});
        } else {
          if (value is Map) value = value;
          lastNodeInCurrentData!.addAll({firstNodeInNewData: value});
        }
      }
    }
  }

  Map<String, dynamic>? _buildNewNodesTree({
    required dynamic data,
    required List<String> nodesList,
    required int nodeIndex,
    required value,
  }) {
    var nextNodeIndex = nodeIndex + 1;
    if (nodeIndex + 1 < nodesList.length) {
      data[nodesList[nodeIndex]] = {nodesList[nextNodeIndex]: Object()};
      _buildNewNodesTree(
          data: data[nodesList[nodeIndex]],
          nodesList: nodesList,
          nodeIndex: nextNodeIndex,
          value: value);
    } else
      data[nodesList[nodeIndex]] = value;
    return data;
  }

  _getNextNodeData({
    required dynamic data,
    required List<String> nodesList,
    required _Int nodeIndex,
  }) {
    if (nodesList.length <= nodeIndex.value ||
        !(data[nodesList[nodeIndex.value]] is Map)) {
      nodeIndex.increment();
      return data;
    }
    return _getNextNodeData(
      data: data[nodesList[nodeIndex.value]],
      nodesList: nodesList,
      nodeIndex: nodeIndex.increment(),
    );
  }

  dynamic _getCurrentData() {
    var tempData = _data;
    // remove start and end slashes.
    var nodePath = _nodePath.substring(1, _nodePath.length - 1);
    var nodeList = nodePath.split('/');
    if (nodeList.length > 1) {
      for (var i = 0; i < nodeList.length; i++) {
        nodePath = nodeList[i];
        var nonExistentNodeFound = tempData![nodePath] == null;
        if (nonExistentNodeFound || (i + 1) == nodeList.length) {
          break;
        }
        if (tempData[nodePath] is Map) {
          tempData = tempData[nodePath];
        }
      }
    }

    return tempData![nodePath];
  }

  @override

  /// __WARNING!__ For now only the DatabaseEventType.value event is supported.
  Future<DatabaseEvent> once(
      [DatabaseEventType eventType = DatabaseEventType.value]) {
    var tempData = _getCurrentData();
    return Future.value(MockDatabaseEvent(MockDataSnapshot(this, tempData)));
  }

  @override
  Future<DataSnapshot> get() {
    var tempData = _getCurrentData();
    return Future.value(MockDataSnapshot(this, tempData));
  }
}

class _Int {
  int value;

  _Int(this.value);

  _Int increment() {
    ++value;
    return this;
  }
}

// Map<String, dynamic> _makeSupportGenericValue(Map<String, dynamic> data) {
//   var _dataWithGenericValue = {'__generic_mock_data_value__': Object()};
//   _dataWithGenericValue.addAll(data);
//   _dataWithGenericValue.forEach((key, value) {
//     if (value is Map) {
//       _dataWithGenericValue[key] = _makeSupportGenericValue(value);
//     }
//   });
//   return _dataWithGenericValue;
// }
