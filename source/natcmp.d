private import std.string;
private import std.algorithm;
private import std.conv;
private import std.array;
private import std.path;
private import std.ascii;

enum compareMode { Undefined, String, Integer }; ///Marks the chunk type
/**
 * A chunk of text, representing either a string of numbers or a string of other characters.
 * Do not use.
 * Authors: Cameron "Herringway" Ross
 */
private struct naturalCompareChunk {
	public char[] str;
	public compareMode mode = compareMode.Undefined;
	/**
	 * Compares two chunks.
	 * Integers are assumed to come before non-integers.
	 * Returns: 0 on failure, [-1,1] on success
	 */
	public int opCmp(ref const naturalCompareChunk b) nothrow @safe {
		scope(failure) return 0;
		assert(this.mode != compareMode.Undefined, "Undefined chunk type (A)");
		assert(   b.mode != compareMode.Undefined, "Undefined chunk type (B)");
		foreach (character; str) {
			if (this.mode == compareMode.Integer)
				assert(character.isDigit(), "Non-numeric value found in number string");
			else
				assert(!character.isDigit(), "Numeric value found in non-numeric string");
		}
		if ((this.mode == compareMode.Integer) && (b.mode == compareMode.String)) {
			return -1;
		} else if ((this.mode == compareMode.String) && (b.mode == compareMode.Integer)) {
			return 1;
		} else if (this.mode == compareMode.String) {
			return min(1, max(-1, icmp(this.str, b.str)));
		} else if (this.mode == compareMode.Integer) {
			return cast(int)max(-1,min(1,to!long(this.str)-to!long(b.str)));
		}
		assert(false, "Default value should never be returned!");
	}
}
unittest {
	naturalCompareChunk chunkA;
	naturalCompareChunk chunkB;
	chunkA = naturalCompareChunk("a".dup, compareMode.String);
	chunkB = naturalCompareChunk("a".dup, compareMode.String);
	assertEqual(chunkA.opCmp(chunkB), 0, "Equal chunks tested as inequal");
	chunkA = naturalCompareChunk("a".dup, compareMode.String);
	chunkB = naturalCompareChunk("b".dup, compareMode.String);
	assert(chunkA < chunkB, "a > b");
	chunkA = naturalCompareChunk("b".dup, compareMode.String);
	chunkB = naturalCompareChunk("a".dup, compareMode.String);
	assert(chunkA > chunkB, "b < a");
	chunkA = naturalCompareChunk("1".dup, compareMode.Integer);
	chunkB = naturalCompareChunk("a".dup, compareMode.String);
	assert(chunkA < chunkB, "1 > a");
	chunkA = naturalCompareChunk("a".dup, compareMode.String);
	chunkB = naturalCompareChunk("1".dup, compareMode.Integer);
	assert(chunkA > chunkB, "a < 1");
	chunkA = naturalCompareChunk("1".dup, compareMode.Integer);
	chunkB = naturalCompareChunk("2".dup, compareMode.Integer);
	assert(chunkA < chunkB, "1 > 2");
	chunkA = naturalCompareChunk("1".dup, compareMode.Integer);
	chunkB = naturalCompareChunk("3".dup, compareMode.Integer);
	assertEqual(chunkA.opCmp(chunkB), -1, "(1 > 3) > 1");
	chunkA = naturalCompareChunk("3".dup, compareMode.Integer);
	chunkB = naturalCompareChunk("1".dup, compareMode.Integer);
	assertEqual(chunkA.opCmp(chunkB), 1, "(3 > 1) < -1");
	chunkA = naturalCompareChunk("a".dup, compareMode.String);
	chunkB = naturalCompareChunk("c".dup, compareMode.String);
	assertEqual(chunkA.opCmp(chunkB), -1, "(a > c) > 1");
	chunkA = naturalCompareChunk("c".dup, compareMode.String);
	chunkB = naturalCompareChunk("a".dup, compareMode.String);
	assertEqual(chunkA.opCmp(chunkB), 1, "(c > a) > 1");
}
/**
 * Compares two strings in a way that is natural to humans. 
 * Integers come before non-integers, and integers are compared as if they were numbers instead of strings of characters.
 * Intended for usage in opCmp overloads.
 * Examples:
 * --------------------
 * struct someStruct {
 *     string someText;
 *     int opCmp(someStruct b) {
 *          return compareNatural(this.someText, b.someText);
 *     }
 * }
 * --------------------
 * Returns: -1 if a comes before b, 0 if a and b are equal, 1 if a comes after b
 */
int compareNatural(inout char[] a, inout char[] b) nothrow @safe {
	naturalCompareChunk[] buildChunkList(inout char[] str) nothrow {
		naturalCompareChunk tempChunk;
		naturalCompareChunk[] output;
		foreach (character; str) {
			if (character.isDigit()) {
				if (tempChunk.mode == compareMode.Integer)
					tempChunk.str ~= character;
				if (tempChunk.mode == compareMode.Undefined) {
					tempChunk.str = [character];
					tempChunk.mode = compareMode.Integer;
				}
				if (tempChunk.mode == compareMode.String) {
					output ~= tempChunk;
					tempChunk = naturalCompareChunk([character],compareMode.Integer);
				}
			} else {
				if (tempChunk.mode == compareMode.String)
					tempChunk.str ~= character;
				if (tempChunk.mode == compareMode.Undefined) {
					tempChunk.str = [character];
					tempChunk.mode = compareMode.String;
				}
				if (tempChunk.mode == compareMode.Integer) {
					output  ~= tempChunk;
					tempChunk = naturalCompareChunk([character],compareMode.String);
				}
			}
		}
		output ~= tempChunk;
		return output;
	}
	naturalCompareChunk[] chunkA = buildChunkList(a);
	naturalCompareChunk[] chunkB = buildChunkList(b);
	int cmpVal;
	foreach (index; 0..min(chunkA.length, chunkB.length)) {
		cmpVal = chunkA[index].opCmp(chunkB[index]);
		if (cmpVal != 0)
			return cmpVal;
	}
	if (chunkA.length > chunkB.length)
		return 1;
	if (chunkA.length < chunkB.length)
		return -1;
	return 0;
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
}

/** 
* Natural string comparison function for use with phobos's sorting algorithm
* Examples:
* --------------------
* assert(sort!compareNaturalSort(array(["0", "10", "1"])) == ["0", "1", "10"]);
* assert(sort!compareNaturalSort(array(["a", "c", "b"])) == ["a", "b", "c"]);
* assert(sort!compareNaturalSort(array(["a1", "a"])) == ["a", "a1"]);
* --------------------
* Returns: true if a < b
*/
bool compareNaturalSort(inout(char[]) a, inout(char[]) b) {
	return compareNatural(b,a) > 0;
}
unittest {
	assertEqual(compareNaturalSort("a", "b"), true);
	assertEqual(array(sort!compareNaturalSort(["0", "10", "1"])), ["0", "1", "10"]);
	assertEqual(array(sort!compareNaturalSort(["a", "c", "b"])), ["a", "b", "c"]);
	assertEqual(array(sort!compareNaturalSort(["a1", "a"])), ["a", "a1"]);
}
/**
 * Compares path strings naturally. Comparing paths naturally requires path separators to be treated specially.
 * Intended for usage in opCmp overloads.
 * Examples:
 * --------------------
 * struct someStruct {
 *     string someText;
 *     int opCmp(someStruct b) {
 *          return comparePathsNatural(this.someText, b.someText);
 *     }
 * }
 * --------------------
 * Returns: -1 if a comes before b, 0 if a and b are equal, 1 if a comes after b
 */
int comparePathsNatural(inout(char[]) pathA, inout(char[]) pathB) nothrow @safe {
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
/** 
 * Path comparison function for use with phobos's sorting algorithm
 * Examples:
 * --------------------
 * assert(array(sort!comparePathsNaturalSort(["a/b/c", "a/b/e", "a/b/d"])) == ["a/b/c", "a/b/d", "a/b/e"]);
 * assert(array(sort!comparePathsNaturalSort(["a1", "a"])) == ["a", "a1"]);
 * assert(array(sort!comparePathsNaturalSort(["a1/b", "a/b"])) == ["a/b", "a1/b"]);
 * --------------------
 * Returns: true if a < b
 */
bool comparePathsNaturalSort(inout(char[]) a, inout(char[]) b) {
	return comparePathsNatural(b,a) > 0;
}

unittest {
	assertEqual(comparePathsNaturalSort("a/b", "a1/b"), true);
	assert(array(sort!comparePathsNaturalSort(["a/b/c", "a/b/e", "a/b/d"])) == ["a/b/c", "a/b/d", "a/b/e"]);
	assert(array(sort!comparePathsNaturalSort(["a1", "a"])) == ["a", "a1"]);
	assert(array(sort!comparePathsNaturalSort(["a1/b", "a/b"])) == ["a/b", "a1/b"]);
}
unittest {
	assertEqual(comparePathsNatural("a/b/c", "a/b/d"), -1, "Final path component sorting failed");
	assertEqual(comparePathsNatural("a/b/c", "a/b/d"), -1, "Final path component sorting failed");
	assertEqual(comparePathsNatural("a/b/c", "a/b/c"), 0, "Identical path sorting failed");
	assertEqual(comparePathsNatural("a/b/c", "a/b/a"), 1, "Final path component sorting failed (2)");
	assertEqual(comparePathsNatural("a/b/c", "a/c/c"), -1, "Middle path component sorting failed");
	assertEqual(comparePathsNatural("a/c/c", "a/b/c"), 1, "Middle path component sorting failed (2)");
	assertEqual(comparePathsNatural("a/b/c", "b/b/c"), -1, "First path component sorting failed");
	assertEqual(comparePathsNatural("b/b/c", "a/b/c"), 1, "First path component sorting failed (2)");
	assertEqual(comparePathsNatural("a/b", "a1/b"), -1, "Appended chunk sorting failed");
	assertEqual(comparePathsNatural("a1/b", "a/b"), 1, "Appended chunk sorting failed (2)");
}
private void assertEqual(T,U)(lazy T valA, lazy U valB, string message = "") {
	try {
		if (valA != valB)
			throw new core.exception.AssertError(format("%s: %s != %s",message, valA, valB));
	} catch (Exception e) {
		throw new core.exception.AssertError(e.msg);
	}
}