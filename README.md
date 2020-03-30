A Unicode-Based Extension to XPath functions that use regular expressions.

Functions `rgx:matches()`, `rgx:replace()`, `rgx:tokenize()`, `rgx:analyze-string()` (in the TAN namespace, tan:textalign.net,2015:ns) behave exactly like the standard functions (namespace http://www.w3.org/2005/xpath-functions) but permit the escape character `\u{}`, which takes four types of constructions.

1. hexadecimal codepoints, e.g., `\u{3f-4a, 1faa}`.
1. Unicode name words, e.g., `\u{.omega!greek}` (any Unicode character whose name includes the word "OMEGA" but not the word "GREEK").
1. Unicode composites, e.g., `\u{+b}` (any Unicode character that can be decomposed to a "b", e.g., bᵇḃḅḇ.
1. Unicode simple decompositions, e.g., `\u{-ǡḃčď}` (converts the character class to 'abcd').

If a particular version of Unicode is desired, use the `$flags` parameter, e.g., `rgx:matches($input-text, '\u{.bottle}', '11.0')`.

Other useful functions:
* `rgx:string-to-components()`. Takes each character in an input string and returns a concatenation of its decomposed components.
* `rgx:string-to-composites()`. Takes each character in an input string and returns a concatenation of characters that can decompose to that character.
* `rgx:string-base()`. Changes in an input string any characters that can decompose to a single base character.
* `rgx:hex-to-dec()`. Converts hexadecimal numbers to decimal.
* `rgx:dec-to-hex()`. Converts decimal numbers to hexadecimal.
* `rgx:n-to-dec()`. Converts base-n systems (2 through 16, 64) to decimals.
* `rgx:dec-to-n()`. Converts decimals to any base-n system (as above). 

See the subdirectory `tests` for examples and 
[the XSLT function library](regex-ext-tan-functions.xsl) for entire list of functions, with documentation. 

TAN-regex has been developed in service of the Text Alignment Network ([http://textalign.net](http://textalign.net)), but can be used independent of TAN.
