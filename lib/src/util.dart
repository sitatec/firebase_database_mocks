import 'dart:math';

const _pushChars =
    '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';

final nextPushId = (() {
  var _lastPushTime = 0;
  final _lastRandChars = List<int>.generate(12, (index) => 0);
  final _random = Random.secure();

  // now is time in milliseconds since epoch
  return (int now) {
    final duplicateTime = now == _lastPushTime;
    _lastPushTime = now;

    // List<String> but it's actually chars
    final timestampChars = List<String>.generate(8, (index) => '');
    for (var i = 7; i >= 0; i--) {
      timestampChars[i] = _pushChars[now % 64];
      // probably could use bit shift for this, JS version deliberately
      // does not use it, so neither does this
      now ~/= 64;
    }
    assert(now == 0);

    var id = timestampChars.join();

    if (!duplicateTime) {
      for (var i = 0; i < 12; i++) {
        _lastRandChars[i] = _random.nextInt(64);
      }
    } else {
      late int i;
      for (i = 11; i >= 0 && _lastRandChars[i] == 63; i--) {
        _lastRandChars[i] = 0;
      }
      _lastRandChars[i]++;
    }

    for (var i = 0; i < 12; i++) {
      id += _pushChars[_lastRandChars[i]];
    }

    assert(id.length == 20);

    return id;
  };
})();
