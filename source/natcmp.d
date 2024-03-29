/**
 * Natural string comparison
 *
 * This module provides functions for easily sorting and comparing strings.
 * For implementing natural comparison methods in structs, see the NaturalComparable and NaturalPathComparable templates,
 * or the compareNatural and comparePathsNatural functions for a more manual implementation.
 *
 * For sorting ranges of strings, see the compareNaturalSort and comparePathsNaturalSort functions.
 *
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Cameron "Herringway" Ross
 * Copyright: 2015-2016 Cameron "Herringway" Ross
 */
module natcmp;
private import std.algorithm.searching : all;
private import std.path : isValidPath;
private import std.traits : FunctionAttribute, functionAttributes, isCallable, isSomeString;
private import std.uni : isNumber;
private import std.utf : toUTF8;
private struct NaturalCompareChunk(T = const(dchar)[]) {
	enum CompareMode { String, Integer }
	public T str;
	public CompareMode mode;
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
	public int opCmp(const NaturalCompareChunk b) const pure @safe
		out(result; result <= 1, "Result too large")
		out(result; result >= -1, "Result too small")
		in(str.all!(character => (mode == CompareMode.Integer) ^ !character.isNumber), "Mismatched value found in string")
	{
		import std.algorithm : clamp, cmp;
		import std.conv : to;
		import std.uni : icmp;
		if (this.mode != b.mode) {
			if ((this.mode == CompareMode.Integer) && (b.mode == CompareMode.String))
				return -1;
			else
				return 1;
		} else {
			final switch(this.mode) {
				case CompareMode.String:
					return clamp(icmp(this.str, b.str), -1, 1);
				case CompareMode.Integer:
					immutable int1 = this.str.to!long;
					immutable int2 = b.str.to!long;
					if (int1 == int2)
						return clamp(icmp(this.str, b.str), -1, 1);
					if (int1 > int2)
						return 1;
					return -1;
			}
		}
	}
	public bool opEquals(const NaturalCompareChunk b) const pure @safe {
		import std.conv : to;
		import std.uni : icmp;
		if (this.mode != b.mode)
			return false;
		else {
			final switch(this.mode) {
				case CompareMode.String:
					return icmp(this.str,b.str) == 0;
				case CompareMode.Integer:
					return this.str == b.str;
			}
		}
	}
	alias str this;
	//TODO: implement proper toHash for completeness
}
@safe pure unittest {
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
	auto testAssoc = [chunkA: "a", chunkB: "b"];
	assert(testAssoc[chunkA] != testAssoc[chunkB]);
}
/**
 * Compares two strings in a way that is natural to humans.
 * Integers come before non-integers, and integers are compared as if they were numbers instead of strings of characters.
 * Best used in opCmp overloads.
 *
 * Returns: -1 if a comes before b, 0 if a and b are equal, 1 if a comes after b
 */
int compareNatural(T)(const T a, const T b) if (isSomeString!T)
	out(result; result <= 1, "Result too large")
	out(result; result >= -1, "Result too small")
{
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
		if (chunkA != chunkB)
			return chunkA > chunkB ? 1 : -1;
	}
	if (!chunksA.empty && chunksB.empty)
		return 1;
	if (chunksA.empty && !chunksB.empty)
		return -1;
	return 0;
}
@safe pure unittest {
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
	assert(compareNatural("PG10", "Pg11") != compareNatural("Pg11", "PG10"));
	assert(compareNatural("01", "1") != compareNatural("1", "01"));
}
private mixin template NaturalComparableCommon(alias comparator, alias T) if (!isCallable!T || (functionAttributes!T & (FunctionAttribute.safe | FunctionAttribute.nothrow_ | FunctionAttribute.const_))) {
	import std.string : split;
	alias __NaturalComparabletype = typeof(this);
	enum __NaturalComparablemember = T.stringof.split(".")[$-1].split("(")[0];
    int opCmp(const __NaturalComparabletype b) const {
    	return comparator(T, __traits(getMember, b, __NaturalComparablemember));
    }
    bool opEquals(const __NaturalComparabletype b) const {
    	return T == __traits(getMember, b, __NaturalComparablemember);
    }
    size_t toHash() const nothrow {
    	return hashOf(T);
    }
}
/**
 * Automatically generates natural-comparing opCmp, opEquals and toHash methods for a particular property or method.
 * Methods must be @safe, nothrow, and const.
 */
mixin template NaturalComparable(alias T) {
	mixin NaturalComparableCommon!(compareNatural, T);
}
///
@safe pure unittest {
	struct SomeStruct {
		dstring someText;
		mixin NaturalComparable!someText;
	}
	struct SomeStructWithFunction {
		dstring _value;
		dstring something() const nothrow @safe {
			return _value;
		}
		mixin NaturalComparable!something;
	}
	assert(SomeStruct("100") > SomeStruct("2"));
	assert(SomeStruct("100") == SomeStruct("100"));
	assert(SomeStructWithFunction("100") > SomeStructWithFunction("2"));
	assert(SomeStructWithFunction("100") == SomeStructWithFunction("100"));
}
@safe pure unittest {
	struct SomeStruct {
		dstring someText;
		mixin NaturalComparable!someText;
	}
	struct SomeStructWithFunction {
		dstring _value;
		dstring something() const nothrow @safe {
			return _value;
		}
		mixin NaturalComparable!something;
	}
	{
		auto data = [SomeStruct("1") : "test", SomeStruct("2"): "test2"];
		assert(data[SomeStruct("1")] == "test");
		assert(data[SomeStruct("2")] == "test2");
	}
	{
		auto data = [SomeStructWithFunction("1") : "test", SomeStructWithFunction("2"): "test2"];
		assert(data[SomeStructWithFunction("1")] == "test");
		assert(data[SomeStructWithFunction("2")] == "test2");
	}
}

/**
* Natural string comparison function for use with phobos's sorting algorithm
*
* Returns: true if a < b
*/
bool compareNaturalSort(T)(const T a, const T b) if (isSomeString!T) {
	return compareNatural(a,b) < 0;
}
///
@safe pure unittest {
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
int comparePathsNatural(T)(const T pathA, const T pathB) if (isSomeString!T)
	in(pathA.isValidPath(), ("First path ("~pathA~") is invalid").toUTF8)
	in(pathB.isValidPath(), ("Second path ("~pathB~") is invalid").toUTF8)
	out(result; result <= 1, "Result too large")
	out(result; result >= -1, "Result too small")
{
	import std.path : pathSplitter;
	import std.range : zip;
	int outVal = 0;
	foreach (componentA, componentB; zip(pathSplitter(pathA), pathSplitter(pathB))) {
		outVal = compareNatural(componentA, componentB);
		if (outVal != 0)
			break;
	}
	return outVal;
}
@safe pure unittest {
	import std.path : buildPath;
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
	assert(comparePathsNatural(buildPath("a", "b", "c"), buildPath("a", "b", "d")) == -1, "failure to sort rangified path");
}
/**
 * Automatically generates natural-path-comparing opCmp, opEquals and toHash methods for a particular property or method.
 * Methods must be @safe, nothrow, and const.
 */
mixin template NaturalPathComparable(alias T) {
	mixin NaturalComparableCommon!(comparePathsNatural, T);
}
///
@safe pure unittest {
	struct SomePathStruct {
		dstring somePathText;
		mixin NaturalPathComparable!somePathText;
	}
	struct SomePathStructWithFunction {
		dstring _value;
		dstring path() const @safe nothrow {
			return _value;
		}
		mixin NaturalPathComparable!path;
	}
	assert(SomePathStruct("a/b/c") < SomePathStruct("a/b/d"));
	assert(SomePathStructWithFunction("a/b/c") < SomePathStructWithFunction("a/b/d"));
}
/**
 * Path comparison function for use with phobos's sorting algorithm
 *
 * Returns: true if a < b
 */
bool comparePathsNaturalSort(T)(const T a, const T b) if (isSomeString!T) {
	return comparePathsNatural(b,a) > 0;
}
///
@safe pure unittest {
	import std.algorithm : sort, equal;
	import std.array : array;
	assert(comparePathsNaturalSort("a/b", "a1/b") == true);
	assert(equal(sort!comparePathsNaturalSort(["a/b/c", "a/b/e", "a/b/d"]), ["a/b/c", "a/b/d", "a/b/e"]));
	assert(equal(sort!comparePathsNaturalSort(["a1", "a"]), ["a", "a1"]));
	assert(equal(sort!comparePathsNaturalSort(["a1/b", "a/b"]), ["a/b", "a1/b"]));
}