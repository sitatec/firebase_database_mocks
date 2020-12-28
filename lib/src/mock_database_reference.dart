import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';

import 'mock_data_snapshot.dart';
import 'mock_firebase_database.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {
  var _nodePath = '/';
  // ignore: prefer_final_fields
  static final _persitedData = <String, dynamic>{};
  var _volatileData = <String, dynamic>{};
  MockDatabaseReference();
  MockDatabaseReference._(nodePath, [this._volatileData]) {
    _nodePath += nodePath;
  }

  Map<String, dynamic> get _data {
    if (MockFirebaseDatabase.persistData) {
      return _persitedData;
    }
    return _volatileData;
  }

  @override
  String get path => _nodePath;

  @override
  DatabaseReference child(String path) {
    if (!path.endsWith('/')) path += '/';
    path = (_nodePath + path).replaceAll(RegExp(r'^/+'), '');
    return MockDatabaseReference._(
      path,
      MockFirebaseDatabase.persistData ? _volatileData : <String, dynamic>{},
    );
  }

  @override
  // ignore: missing_return
  Future<void> set(dynamic value, {dynamic priority}) {
    var nodePathWithoutSlashesAtEndAndStart =
        _nodePath.substring(1, _nodePath.length - 1);
    var nodesList = nodePathWithoutSlashesAtEndAndStart.split('/');
    var tempData = <String, dynamic>{};
    Map<String, dynamic> lastNodeInCurrentData;
    var nodeIndexReference = _Int(0);
    if (_data.isEmpty) {
      lastNodeInCurrentData = _data;
    } else {
      lastNodeInCurrentData = getNode(
        data: _data,
        nodesList: nodesList,
        nodeIndex: nodeIndexReference.increment(),
      );
    }
    var nodeIndex = nodeIndexReference.value;
    if (nodesList.length <= nodeIndex) {
      lastNodeInCurrentData[nodesList.last] = value;
      return null;
    }
    var firstNodeInNewData = nodesList[nodeIndex++];
    if (nodeIndex < nodesList.length) {
      for (; nodeIndex < nodesList.length; nodeIndex++) {
        if (nodeIndex + 1 < nodesList.length) {
          tempData[nodesList[nodeIndex]] = {nodesList[nodeIndex + 1]: null};
          tempData = tempData[nodesList[nodeIndex]];
        } else {
          tempData[nodesList[nodeIndex]] = value;
        }
      }
      lastNodeInCurrentData
          .addAll({firstNodeInNewData: _makeSupportGenericValue(tempData)});
    } else {
      if (value is Map) value = _makeSupportGenericValue(value);
      lastNodeInCurrentData.addAll({firstNodeInNewData: value});
    }
  }

  dynamic getNode(
      {@required dynamic data,
      @required List<String> nodesList,
      @required _Int nodeIndex}) {
    // print(data);
    // print(nodeIndex.value);
    if (nodesList.length == nodeIndex.value ||
        !(data[nodesList[nodeIndex.value]] is Map)) return data;
    return getNode(
        data: data[nodesList[nodeIndex.value]],
        nodesList: nodesList,
        nodeIndex: nodeIndex.increment());
  }

  @override
  Future<DataSnapshot> once() {
    return Future(() {
      var tempData = _data;
      var nodePath = _nodePath.substring(1, _nodePath.length - 1);
      var nodeList = nodePath.split('/');
      if (nodeList.length > 1) {
        for (var node in nodeList) {
          nodePath = node;
          if (tempData[node] == null) {
            nodePath = '';
            break;
          }
          if (tempData[node] is Map) {
            tempData = tempData[node];
          }
        }
      }
      return MockDataSnapshot(tempData[nodePath]);
    });
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

Map<String, Object> _makeSupportGenericValue(Map<String, dynamic> data) {
  var _dataWithGenericValue = {'__generic_mock_data_value__': Object()};
  _dataWithGenericValue.addAll(data);
  _dataWithGenericValue.forEach((key, value) {
    if (value is Map) {
      _dataWithGenericValue[key] = _makeSupportGenericValue(value);
    }
  });
  return _dataWithGenericValue;
}
