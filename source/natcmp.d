module natcmp;
debug(natcmp) import std.stdio;
private import std.traits : isSomeString;
@safe:
private struct NaturalCompareChunk(T = const(dchar)[]) {
	enum CompareMode { Undefined, String, Integer }
	public T str;
	public CompareMode mode = CompareMode.Undefined;
	this(T input) pure @safe nothrow @nogc {
		import std.uni : isNumber;
		str = input;
		mode = input[0].isNumber ? CompareMode.Integer : CompareMode.String;
	}
	/**
	 * Compares two chunks.
	 * Integers are assumed to come before non-integers.
	 *
	 * Returns: -1 if a comes before b, 0 if a and b are equal, 1 if a comes after b
	 */
	public int opCmp(in NaturalCompareChunk b) const pure @safe in {
		import std.uni : isNumber;
		assert(this.mode != CompareMode.Undefined, "Undefined chunk type (A)");
		assert(   b.mode != CompareMode.Undefined, "Undefined chunk type (B)");
		foreach (character; str) {
			if (this.mode == CompareMode.Integer)
				assert(character.isNumber(), "Non-numeric value found in number string");
			else
				assert(!character.isNumber(), "Numeric value found in non-numeric string");
		}
	} out(result) {
		assert(result <= 1, "Result too large");
		assert(result >= -1, "Result too small");
	} body {
		import std.algorithm : clamp, cmp;
		import std.conv : to;
		import std.uni : icmp;
		if ((this.mode == CompareMode.Integer) && (b.mode == CompareMode.String)) {
			return -1;
		} else if ((this.mode == CompareMode.String) && (b.mode == CompareMode.Integer)) {
			return 1;
		} else if (this.mode == CompareMode.String) {
			return clamp(icmp(this.str, b.str), -1, 1);
		} else if (this.mode == CompareMode.Integer) {
			auto int1 = this.str.to!long;
			auto int2 = b.str.to!long;
			debug(natcmp) writeln(int1, ",", int2);
			if (int1 == int2)
				return clamp(icmp(this.str, b.str), -1, 1);
			if (int1 > int2)
				return 1;
			return -1;
		} else
			assert(false);
	}
	public bool opEquals(in NaturalCompareChunk b) const pure @safe {
		import std.conv : to;
		if (mode != b.mode)
			return false;
		else if (mode == CompareMode.String)
			return str == b.str;
		else if (mode == CompareMode.Integer)
			return str.to!long == b.str.to!long;
		else
			assert(0);
	}
	public size_t toHash() const pure @safe nothrow {
		return hashOf(str);
	}
}
unittest {
	import std.algorithm : equal;
	NaturalCompareChunk!dstring chunkA;
	NaturalCompareChunk!dstring chunkB;
	chunkA = NaturalCompareChunk!dstring("a");
	chunkB = NaturalCompareChunk!dstring("a");
	assert((chunkA >= chunkB) && (chunkA <= chunkB), "a == a");
	chunkA = NaturalCompareChunk!dstring("a");
	chunkB = NaturalCompareChunk!dstring("b");
	assert(chunkA < chunkB, "a > b");
	chunkA = NaturalCompareChunk!dstring("b");
	chunkB = NaturalCompareChunk!dstring("a");
	assert(chunkA > chunkB, "b < a");
	chunkA = NaturalCompareChunk!dstring("1");
	chunkB = NaturalCompareChunk!dstring("a");
	assert(chunkA < chunkB, "1 > a");
	chunkA = NaturalCompareChunk!dstring("a");
	chunkB = NaturalCompareChunk!dstring("1");
	assert(chunkA > chunkB, "a < 1");
	chunkA = NaturalCompareChunk!dstring("1");
	chunkB = NaturalCompareChunk!dstring("2");
	assert(chunkA < chunkB, "1 > 2");
	chunkA = NaturalCompareChunk!dstring("3");
	chunkB = NaturalCompareChunk!dstring("1");
	assert(chunkA > chunkB, "1 > 3");
	chunkA = NaturalCompareChunk!dstring("3");
	chunkB = NaturalCompareChunk!dstring("1");
	assert(chunkA > chunkB, "3 > 1");
	chunkA = NaturalCompareChunk!dstring("c");
	chunkB = NaturalCompareChunk!dstring("a");
	assert(chunkA > chunkB, "a > c");
	chunkA = NaturalCompareChunk!dstring("c");
	chunkB = NaturalCompareChunk!dstring("a");
	assert(chunkA > chunkB, "c > a");
	chunkA = NaturalCompareChunk!dstring( "1");
	chunkB = NaturalCompareChunk!dstring("01");
	assert(chunkA > chunkB, "1 > 01");
	chunkA = NaturalCompareChunk!dstring( "01");
	chunkB = NaturalCompareChunk!dstring("001");
	assert(chunkA > chunkB, "01 > 001");
}
/**
 * Compares two strings in a way that is natural to humans.
 * Integers come before non-integers, and integers are compared as if they were numbers instead of strings of characters.
 * Best used in opCmp overloads.
 *
 * Returns: -1 if a comes before b, 0 if a and b are equal, 1 if a comes after b
 */
int compareNatural(T)(in T a, in T b) @trusted if (isSomeString!T) out(result) {
		assert(result <= 1, "Result too large");
		assert(result >= -1, "Result too small");
} body {
	import std.algorithm : min, map, chunkBy;
	import std.uni : isNumber;
	import std.range : walkLength, zip;
	import std.conv : to;
	auto chunksA = a
		.chunkBy!isNumber
		.map!(x => NaturalCompareChunk!T(x[1].to!T));
	auto chunksB = b
		.chunkBy!isNumber
		.map!(x => NaturalCompareChunk!T(x[1].to!T));
	foreach (chunkA, chunkB; zip(chunksA, chunksB)) {
		debug(natcmp) writeln(chunkA, chunkB, chunkA>chunkB, chunkA==chunkB);
		if (chunkA != chunkB)
			return chunkA > chunkB ? 1 : -1;
	}
	debug(natcmp) writeln("len: ", chunksA.empty, ",", chunksB.empty);
	if (!chunksA.empty && chunksB.empty)
		return 1;
	if (chunksA.empty && !chunksB.empty)
		return -1;
	return 0;
}
///
unittest {
	struct SomeStruct {
 		dstring someText;
		int opCmp(in SomeStruct b) const {
 			return compareNatural(this.someText, b.someText);
		}
	}
}
unittest {
	assert(compareNatural("10", "1") == 1, "1 > 10");
	assert(compareNatural("010", "1") == 1, "1 > 010");
	assert(compareNatural("10", "01") == 1, "01 > 10");
	assert(compareNatural("10_1", "1_1") == 1, "1_1 > 10_1");
	assert(compareNatural("10_1", "10_2") == -1, "10_1 > 10_2");
	assert(compareNatural("10_2", "10_1") == 1, "10_1 > 10_2");
	assert(compareNatural("a", "a1") == -1, "a > a1");
	assert(compareNatural("a1", "a") == 1, "a1 < a");
	assert(compareNatural("1000", "something") == -1, "1000 > something");
	assert(compareNatural("something", "1000") == 1, "something < 1000");
	assert(compareNatural("十", "〇") == 1, "Japanese: 10 > 0");
	assert(compareNatural("עֶ֫שֶׂר", "אֶ֫פֶס") == 1, "Biblical Hebrew: 10 > 0");
}

/**
* Natural string comparison function for use with phobos's sorting algorithm
*
* Returns: true if a < b
*/
bool compareNaturalSort(T)(in T a, in T b) if (isSomeString!T) {
	return compareNatural(b,a) > 0;
}
///
unittest {
	import std.algorithm : sort, equal;
	import std.array : array;
	assert(compareNaturalSort("a", "b") == true);
	assert(equal(sort!compareNaturalSort(["0", "10", "1"]), ["0", "1", "10"]));
	assert(equal(sort!compareNaturalSort(["a", "c", "b"]), ["a", "b", "c"]));
	assert(equal(sort!compareNaturalSort(["a1", "a"]), ["a", "a1"]));
}
/**
 * Compares path strings naturally. Comparing paths naturally requires path separators to be treated specially.
 * Intended for usage in opCmp overloads.
 *
 * Returns: -1 if a comes before b, 0 if a and b are equal, 1 if a comes after b
 */
int comparePathsNatural(T)(in T pathA, in T pathB) if (isSomeString!T) in {
	import std.path : isValidPath;
	import std.utf : toUTF8;
	assert(pathA.isValidPath(), ("First path ("~pathA~") is invalid").toUTF8);
	assert(pathB.isValidPath(), ("Second path ("~pathB~") is invalid").toUTF8);
} out(result) {
	assert(result <= 1, "Result too large");
	assert(result >= -1, "Result too small");
} body {
	import std.algorithm : min;
	import std.array : array;
	import std.path : pathSplitter;
	auto pathSplitA = array(pathSplitter(pathA));
	auto pathSplitB = array(pathSplitter(pathB));
	int outVal = 0;
	foreach (index; 0..min(pathSplitA.length, pathSplitB.length)) {
		outVal = compareNatural(pathSplitA[index], pathSplitB[index]);
		if (outVal != 0)
			break;
	}
	return outVal;
}
///
unittest {
	struct SomePathStruct {
 		dstring somePathText;
		int opCmp(SomePathStruct b) const {
 			return comparePathsNatural(this.somePathText, b.somePathText);
		}
		bool opEquals(SomePathStruct b) const {return somePathText == b.somePathText; }
		auto toHash() const { return hashOf(somePathText); }
	}
}
unittest {
	assert(comparePathsNatural("a/b/c", "a/b/d") == -1, "Final path component sorting failed");
	assert(comparePathsNatural("a/b/c", "a/b/d") == -1, "Final path component sorting failed");
	assert(comparePathsNatural("a/b/c", "a/b/c") == 0, "Identical path sorting failed");
	assert(comparePathsNatural("a/b/c", "a/b/a") == 1, "Final path component sorting failed (2)");
	assert(comparePathsNatural("a/b/c", "a/c/c") == -1, "Middle path component sorting failed");
	assert(comparePathsNatural("a/c/c", "a/b/c") == 1, "Middle path component sorting failed (2)");
	assert(comparePathsNatural("a/b/c", "b/b/c") == -1, "First path component sorting failed");
	assert(comparePathsNatural("b/b/c", "a/b/c") == 1, "First path component sorting failed (2)");
	assert(comparePathsNatural("a/b", "a1/b") == -1, "Appended chunk sorting failed");
	assert(comparePathsNatural("a1/b", "a/b") == 1, "Appended chunk sorting failed (2)");
}
/**
 * Path comparison function for use with phobos's sorting algorithm
 *
 * Returns: true if a < b
 */
bool comparePathsNaturalSort(T)(in T a, in T b) if (isSomeString!T) {
	return comparePathsNatural(b,a) > 0;
}
///
unittest {
	import std.algorithm : sort, equal;
	import std.array : array;
	assert(comparePathsNaturalSort("a/b", "a1/b") == true);
	assert(equal(sort!comparePathsNaturalSort(["a/b/c", "a/b/e", "a/b/d"]), ["a/b/c", "a/b/d", "a/b/e"]));
	assert(equal(sort!comparePathsNaturalSort(["a1", "a"]), ["a", "a1"]));
	assert(equal(sort!comparePathsNaturalSort(["a1/b", "a/b"]), ["a/b", "a1/b"]));
}