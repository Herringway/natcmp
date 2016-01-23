# Natcmp
[![Build Status](https://travis-ci.org/Herringway/natcmp.svg?branch=master)](https://travis-ci.org/Herringway/natcmp)
[![Coverage Status](https://coveralls.io/repos/Herringway/natcmp/badge.svg?branch=master&service=github)](https://coveralls.io/github/Herringway/natcmp?branch=master)
Natcmp is a library for comparing strings and paths in a way more familiar to humans.

For a list of strings like [a, 100, 10, b, 2], sorting ASCIIbetically would
produce the unexpected ordering of [10, 100, 2, a, b]. A human would expect an
ordering more like [2, 10, 100, a, b]. This library provides the means to sort
and compare strings in such a fashion.

[Documentation](http://herringway.github.io/natcmp.html)