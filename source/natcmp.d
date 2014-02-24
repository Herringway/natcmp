private import std.string;
private import std.algorithm;
private import std.conv;
private import std.array;
private import std.path;
private import std.ascii;

enum compareMode { Undefined, String, Integer };
struct naturalCompareChunk {
	public char[] str;
	public compareMode mode = compareMode.Undefined;
	public int opCmp(ref const naturalCompareChunk b) nothrow @safe {
		assert(this.mode != compareMode.Undefined, "Undefined chunk type (A)");
		assert(   b.mode != compareMode.Undefined, "Undefined chunk type (B)");
		if ((this.mode == compareMode.Integer) && (b.mode == compareMode.String)) {
			return -1;
		} else if ((this.mode == compareMode.String) && (b.mode == compareMode.Integer)) {
			return 1;
		} else if (this.mode == compareMode.String) {
			try {
				return min(1, max(-1, icmp(this.str, b.str)));
			} catch (Exception) { return 0; }
		} else if (this.mode == compareMode.Integer) {
			try {
				return cast(int)max(-1,min(1,to!long(this.str)-to!long(b.str)));
			} catch (Exception) { return 0; }
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

int comparePathsNatural(string pathA, string pathB) nothrow @safe {
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
private void assertEqual(T,U)(lazy T valA, lazy U valB, string message) {
	try {
		if (valA != valB)
			throw new core.exception.AssertError(format("%s: %s != %s",message, valA, valB));
	} catch (Exception e) {
		throw new core.exception.AssertError(e.msg);
	}
}