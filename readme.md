# Natcmp - A D library for comparing strings and paths in a human-natural way.

## Supported platforms
* Any with D compilers

## Example usage
```D
sort!compareNatural(["0", "10", "1"]) == ["0", "1", "10"]
sort!compareNatural(["a", "c", "b"]) == ["a", "b", "c"]
sort!compareNatural(["a1", "a"]) == ["a", "a1"]

sort!comparePathsNatural(["a/b/c", "a/b/e", "a/b/f"]) == ["a/b/c", "a/b/d", "a/b/e"]
sort!comparePathsNatural(["a1", "a"]) == ["a", "a1"]
sort!comparePathsNatural(["a1/b", "a/b"]) == ["a/b", "a1/b"]
```