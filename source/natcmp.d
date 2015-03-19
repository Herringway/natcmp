module natcmp;

nothrow @safe:
private enum compareMode { Undefined, String, Integer }; ///Marks the chunk type
/**
 * A chunk of text, representing either a string of numbers or a string of other characters.
 * Authors: Cameron "Herringway" Ross
 */
private struct naturalCompareChunk {
	nothrow @safe pure:
	public dstring str;
	public compareMode mode = compareMode.Undefined;
	/**
	 * Compares two chunks.
	 * Integers are assumed to come before non-integers.
	 * Returns: 0 on failure, [-1,1] on success
	 */
	public int opCmp(ref const naturalCompareChunk b) in {
		import std.uni : isNumber;
		assert(this.mode != compareMode.Undefined, "Undefined chunk type (A)");
		assert(   b.mode != compareMode.Undefined, "Undefined chunk type (B)");
		foreach (character; str) {
			if (this.mode == compareMode.Integer)
				assert(character.isNumber(), "Non-numeric value found in number string");
			else
				assert(!character.isNumber(), "Numeric value found in non-numeric string");
		}
	} out(result) {
		assert(result <= 1, "Result too large");
		assert(result >= -1, "Result too small");
	} body {
		import std.algorithm : min, max;
		import std.conv : to;
		import std.uni : icmp;
		try {
			if ((this.mode == compareMode.Integer) && (b.mode == compareMode.String)) {
				return -1;
			} else if ((this.mode == compareMode.String) && (b.mode == compareMode.Integer)) {
				return 1;
			} else if (this.mode == compareMode.String) {
				return min(1, max(-1, icmp(this.str, b.str)));
			} else if (this.mode == compareMode.Integer) {
				auto int1 = to!long(this.str);
				auto int2 = to!long(b.str);
				if (int1 == int2)
					return min(1, max(-1, icmp(this.str, b.str)));
				return cast(int)max(-1,min(1,int1-int2));
			}
		} catch (Exception) {
			return 0;
		}
		assert(false);
	}
}
unittest {
	naturalCompareChunk chunkA;
	naturalCompareChunk chunkB;
	chunkA = naturalCompareChunk("a", compareMode.String);
	chunkB = naturalCompareChunk("a", compareMode.String);
	assertEqual(chunkA.opCmp(chunkB), 0, "Equal chunks tested as inequal");
	chunkA = naturalCompareChunk("a", compareMode.String);
	chunkB = naturalCompareChunk("b", compareMode.String);
	assert(chunkA < chunkB, "a > b");
	chunkA = naturalCompareChunk("b", compareMode.String);
	chunkB = naturalCompareChunk("a", compareMode.String);
	assert(chunkA > chunkB, "b < a");
	chunkA = naturalCompareChunk("1", compareMode.Integer);
	chunkB = naturalCompareChunk("a", compareMode.String);
	assert(chunkA < chunkB, "1 > a");
	chunkA = naturalCompareChunk("a", compareMode.String);
	chunkB = naturalCompareChunk("1", compareMode.Integer);
	assert(chunkA > chunkB, "a < 1");
	chunkA = naturalCompareChunk("1", compareMode.Integer);
	chunkB = naturalCompareChunk("2", compareMode.Integer);
	assert(chunkA < chunkB, "1 > 2");
	chunkA = naturalCompareChunk("1", compareMode.Integer);
	chunkB = naturalCompareChunk("3", compareMode.Integer);
	assertEqual(chunkA.opCmp(chunkB), -1, "(1 > 3) > 1");
	chunkA = naturalCompareChunk("3", compareMode.Integer);
	chunkB = naturalCompareChunk("1", compareMode.Integer);
	assertEqual(chunkA.opCmp(chunkB), 1, "(3 > 1) < -1");
	chunkA = naturalCompareChunk("a", compareMode.String);
	chunkB = naturalCompareChunk("c", compareMode.String);
	assertEqual(chunkA.opCmp(chunkB), -1, "(a > c) > 1");
	chunkA = naturalCompareChunk("c", compareMode.String);
	chunkB = naturalCompareChunk("a", compareMode.String);
	assertEqual(chunkA.opCmp(chunkB), 1, "(c > a) > 1");
	chunkA = naturalCompareChunk( "1", compareMode.Integer);
	chunkB = naturalCompareChunk("01", compareMode.Integer);
	assertEqual(chunkA.opCmp(chunkB), 1, "(1 > 01) > 1");
	chunkA = naturalCompareChunk( "01", compareMode.Integer);
	chunkB = naturalCompareChunk("001", compareMode.Integer);
	assertEqual(chunkA.opCmp(chunkB), 1, "(01 > 001) > 1");
}
/**
 * Splits a string into component chunks. Each component is treated either as an integer or a string.
 * Returns: A list of prepared string chunks
 */
private naturalCompareChunk[] buildChunkList(inout dchar[] str) pure in {
	//Unsure if there are any constraints on input
} out(result) {
	foreach (chunk; result)
		assert(chunk.mode != compareMode.Undefined, "Undefined chunk type");
} body {
	import std.uni : isNumber;
	naturalCompareChunk tempChunk;
	naturalCompareChunk[] output;
	foreach (character; str) {
		if (character.isNumber()) {
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
/**
 * Compares two strings in a way that is natural to humans. 
 * Integers come before non-integers, and integers are compared as if they were numbers instead of strings of characters.
 * Intended for usage in opCmp overloads.
 * Examples:
 * --------------------
 * struct someStruct {
 *     dstring someText;
 *     int opCmp(someStruct b) {
 *          return compareNatural(this.someText, b.someText);
 *     }
 * }
 * --------------------
 * Returns: -1 if a comes before b, 0 if a and b are equal, 1 if a comes after b
 */
int compareNatural(inout dchar[] a, inout dchar[] b) pure in {

	} out(result) {
		assert(result <= 1, "Result too large");
		assert(result >= -1, "Result too small");
	} body {
	import std.algorithm : min;
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
/**
 * Overload for 8-bit strings
 */
int compareNatural(inout char[] a, inout char[] b) pure {
	import std.utf : toUTF32;
	try {
		return compareNatural(a.toUTF32(), b.toUTF32());
	} catch (Exception) { return 0; }
}
/**
 * Overload for 16-bit strings
 */
int compareNatural(inout wchar[] a, inout wchar[] b) pure {
	import std.utf : toUTF32;
	try {
		return compareNatural(a.toUTF32(), b.toUTF32());
	} catch (Exception) { return 0; }
}
unittest {
	assertEqual(compareNatural("10", "1"), 1, "1 > 10");
	assertEqual(compareNatural("010", "1"), 1, "1 > 010");
	assertEqual(compareNatural("10", "01"), 1, "01 > 10");
	assertEqual(compareNatural("10_1", "1_1"), 1, "1_1 > 10_1");
	assertEqual(compareNatural("10_1", "10_2"), -1, "10_1 > 10_2");
	assertEqual(compareNatural("10_2", "10_1"), 1, "10_1 > 10_2");
	assertEqual(compareNatural("a", "a1"), -1, "a > a1");
	assertEqual(compareNatural("a1", "a"), 1, "a1 < a");
	assertEqual(compareNatural("1000", "something"), -1, "1000 > something");
	assertEqual(compareNatural("something", "1000"), 1, "something < 1000");
	assertEqual(compareNatural("十", "〇"), 1, "Japanese: 10 > 0");
	assertEqual(compareNatural("עֶ֫שֶׂר", "אֶ֫פֶס"), 1, "Biblical Hebrew: 10 > 0");
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
bool compareNaturalSort(inout(dchar[]) a, inout(dchar[]) b) pure {
	return compareNatural(b,a) > 0;
}
/**
 * Overload for 8-bit strings
 */
bool compareNaturalSort(inout(char[]) a, inout(char[]) b) pure {
	import std.utf : toUTF32;
	try {
		return compareNaturalSort(a.toUTF32(), b.toUTF32());
	} catch (Exception) { return 0; }
}
/**
 * Overload for 16-bit strings
 */
bool compareNaturalSort(inout(wchar[]) a, inout(wchar[]) b) pure {
	import std.utf : toUTF32;
	try {
		return compareNaturalSort(a.toUTF32(), b.toUTF32());
	} catch (Exception) { return 0; }
}
@system unittest {
	import std.algorithm : sort;
	import std.array : array;
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
int comparePathsNatural(inout(dchar[]) pathA, inout(dchar[]) pathB) pure in {
	import std.path : isValidPath;
	assert(pathA.isValidPath(), "First path is invalid");
	assert(pathB.isValidPath(), "Second path is invalid");	
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
/**
 * Overload for 8-bit strings
 */
int comparePathsNatural(inout(char[]) pathA, inout(char[]) pathB) pure {
	import std.utf : toUTF32;
	try {
		return comparePathsNatural(pathA.toUTF32(), pathB.toUTF32());
	} catch (Exception) { return 0; }
}
/**
 * Overload for 16-bit strings
 */
int comparePathsNatural(inout(wchar[]) pathA, inout(wchar[]) pathB) pure {
	import std.utf : toUTF32;
	try {
		return comparePathsNatural(pathA.toUTF32(), pathB.toUTF32());
	} catch (Exception) { return 0; }
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
bool comparePathsNaturalSort(inout(dchar[]) a, inout(dchar[]) b) pure {
	return comparePathsNatural(b,a) > 0;
}

/**
 * Overload for 8-bit strings
 */
bool comparePathsNaturalSort(inout(char[]) a, inout(char[]) b) pure {
	import std.utf : toUTF32;
	try {
		return comparePathsNaturalSort(a.toUTF32(), b.toUTF32());
	} catch (Exception) { return 0; }
}
/**
 * Overload for 16-bit strings
 */
bool comparePathsNaturalSort(inout(wchar[]) a, inout(wchar[]) b) pure {
	import std.utf : toUTF32;
	try {
		return comparePathsNaturalSort(a.toUTF32(), b.toUTF32());
	} catch (Exception) { return 0; }
}
@system unittest {
	import std.algorithm : sort;
	import std.array : array;
	assertEqual(comparePathsNaturalSort("a/b", "a1/b"), true);
	assertEqual(array(sort!comparePathsNaturalSort(["a/b/c", "a/b/e", "a/b/d"])), ["a/b/c", "a/b/d", "a/b/e"]);
	assertEqual(array(sort!comparePathsNaturalSort(["a1", "a"])), ["a", "a1"]);
	assertEqual(array(sort!comparePathsNaturalSort(["a1/b", "a/b"])), ["a/b", "a1/b"]);
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
private void assertEqual(T,U)(lazy T valA, lazy U valB, string message = "") pure {
	import std.string : format;
	try {
		if (valA != valB)
			assert(true, format("%s: %s != %s",message, valA, valB));
	} catch (Exception e) {
		assert(true, e.msg);
	}
}