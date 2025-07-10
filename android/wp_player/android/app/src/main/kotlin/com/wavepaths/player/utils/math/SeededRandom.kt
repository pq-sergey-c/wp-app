// =======[About implementation]=======
// Random algorithm:
// Using xorshiftr128+ (note: with 'r', not a plain xorshift+) - to ensure consistent
// values across different languages (e.g., Dart and Kotlin) for the same seed
//
// String hash algorithm:
// using iterative hash function: hash -> hash * 33 + char.asInt
// =======[                    ]=======

import kotlin.math.max
import kotlin.math.min

/// Just a nice value derived from an equation that uses the golden ratio
private val HASH_CONSTANT: ULong = 0x9E3779B97F4A7C15UL

/// To ensure that s1 or s2 isn't initialized to zero
private val MIN_INIT_VALUE_1: ULong = 1UL

/// To ensure that s2 isn't initialized to zero - second fallback if s1 == first fallback
private val MIN_INIT_VALUE_2: ULong = 2UL

private val MAX_UINT64: ULong = ULong.MAX_VALUE

class SeededRandom(seed: Number) {

    companion object {
        fun fromString(value: String): SeededRandom {

            // specifically not isBlank for the same result in different languages
            if (value.isEmpty()) return SeededRandom(0)

            val hash: UInt =
                    value.map { it.code.toUInt() }.reduce { hash, char ->
                        ((hash shl 5) + hash) + char
                    }
            return SeededRandom(hash.toLong())
        }
    }

    private var s1: ULong
    private var s2: ULong

    init {

        val seedULong = seed.toLong().toULong()
        s1 = if (seedULong == 0UL) MIN_INIT_VALUE_1 else seedULong

        val tempS2 = seedULong xor HASH_CONSTANT
        if (tempS2 != 0UL) {
            s2 = tempS2
        } else {
            s2 = if (s1 != MIN_INIT_VALUE_1) MIN_INIT_VALUE_1 else MIN_INIT_VALUE_2
        }
    }

    /// returns double in range [0; 1)
    operator fun invoke(): Double {
        var x: ULong = s1
        val y: ULong = s2

        // ---
        s1 = s2

        x = x xor (x shl 23)
        x = x xor (x shr 17)
        x = x xor y

        s2 = x + y

        // ---
        val result =
                x.toDouble() /
                        (MAX_UINT64.toDouble() + 1.0) // + 1.0 - to ensure that result in [0, 1)
        return result
    }

    /// returns double in range [start; end)
    /// if start > end -> values are swapped
    fun nextDouble(start: Double, end: Double): Double {
        val a = min(start, end)
        val b = max(start, end)
        return this() * (b - a) + a
    }

    /// returns int in range [start; end]
    /// if start > end -> values are swapped
    fun nextInt(start: Int, end: Int): Int {
        val a = min(start, end)
        val b = max(start, end)
        return nextDouble(a.toDouble(), (b + 1).toDouble()).toInt()
    }
}
