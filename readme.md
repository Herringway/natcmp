# Natcmp - A D library for comparing strings and paths in a human-natural way.
[![Build Status](https://travis-ci.org/Herringway/natcmp.svg?branch=master)](https://travis-ci.org/Herringway/natcmp)
## Supported platforms
* Any with D compilers

## Example usage
```D
assert(array(sort!compareNaturalSort(["0", "10", "1"])) == ["0", "1", "10"]);
assert(array(sort!compareNaturalSort(["a", "c", "b"])) == ["a", "b", "c"]);
assert(array(sort!compareNaturalSort(["a1", "a"])) == ["a", "a1"]);

assert(array(sort!comparePathsNaturalSort(["a/b/c", "a/b/e", "a/b/d"])) == ["a/b/c", "a/b/d", "a/b/e"]);
assert(array(sort!comparePathsNaturalSort(["a1", "a"])) == ["a", "a1"]);
assert(array(sort!comparePathsNaturalSort(["a1/b", "a/b"])) == ["a/b", "a1/b"]);
```