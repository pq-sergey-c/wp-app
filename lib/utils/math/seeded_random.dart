// =======[About implementation]=======
// Random algorithm:
// Using xorshiftr128+ (note: with 'r', not a plain xorshift+) - to ensure consistent
// values across different languages (e.g., Dart and Kotlin) for the same seed
//
// String hash algorithm:
// using iterative hash function: hash -> hash * 33 + char.asInt
// =======[                    ]=======

import 'dart:math';

const int _u64 = 64;
const int _u32 = 32;

/// Just a nice value derived from an equation that uses the golden ratio
final BigInt _hashConstant = BigInt.parse("0x9E3779B97F4A7C15").toUnsigned(_u64);

/// To ensure that s1 or s2 isn't initialized to zero
final BigInt _minInitValue1 = BigInt.from(1).toUnsigned(_u64);

/// To ensure that s2 isn't initialized to zero - second fallback if s1 == first fallback
final BigInt _minInitValue2 = BigInt.from(2).toUnsigned(_u64);

final BigInt _maxUInt64 = BigInt.from(-1).toUnsigned(_u64);

class SeededRandom {
  factory SeededRandom.fromString(String seed) {
    if (seed.isEmpty) return SeededRandom(0);
    final hash = seed.codeUnits
        .map((char) => BigInt.from(char).toUnsigned(_u32))
        .fold(BigInt.zero, (hash, char) => ((hash << 5) + hash) + char);
    return SeededRandom(hash.toUnsigned(_u32).toInt());
  }

  SeededRandom(num seed) {
    final seedBigInt = BigInt.from(seed).toUnsigned(_u64);
    _s1 = seedBigInt == BigInt.from(0) ? _minInitValue1 : seedBigInt;

    final tempS2 = seedBigInt ^ _hashConstant;

    if (tempS2 != BigInt.from(0)) {
      _s2 = tempS2;
    } else {
      _s2 = _s1 != _minInitValue1 ? _minInitValue1 : _minInitValue2;
    }
  }

  late BigInt _s1;
  late BigInt _s2;

  /// returns double in range [0; 1)
  double call() {
    BigInt x = _s1;
    final BigInt y = _s2;

    // ---
    _s1 = _s2;

    x ^= (x << 23).toUnsigned(_u64);
    x ^= (x >> 17).toUnsigned(_u64);
    x ^= y;

    _s2 = (x + y).toUnsigned(_u64);

    // ---
    final result = x.toDouble() / (_maxUInt64.toDouble() + 1.0); // + 1.0 - to ensure that result in [0, 1)
    return result;
  }

  /// returns double in range [start; end)
  /// if start > end -> values are swapped
  double nextDouble({required double start, required double end}) {
    final double a = min(start, end);
    final double b = max(start, end);
    return this() * (b - a) + a;
  }

  /// returns int in range [start; end]
  /// if start > end -> values are swapped
  int nextInt({required int start, required int end}) {
    final int a = min(start, end);
    final int b = max(start, end);
    return nextDouble(start: a.toDouble(), end: (b + 1).toDouble()).floor();
  }
}
