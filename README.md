# TAN-regex

TAN-regex is an XSLT library that extends regular expressions used by XPath functions `matches()`, `replace()`, `tokenize()`, and `analyze-string()`. The parallel TAN-regex functions behave exactly like the standard XPath functions, but permit the escape character `\u{}`, which takes four types of constructions.

1. hexadecimal codepoints, e.g., `\u{3f-4a 1faa}`.
1. Unicode name words, e.g., `\u{.omega!greek}` (any Unicode character whose name includes the word "OMEGA" but not the word "GREEK").
1. Unicode composites, e.g., `\u{+b}` (any Unicode character that can be decomposed to a "b", e.g., bᵇḃḅḇ.
1. Unicode simple decompositions, e.g., `\u{-ǡḃčď}` (converts the character class to 'abcd').

If a particular version of Unicode is desired, use the `$flags` parameter, e.g., `rgx:matches($input-text, '\u{.bottle}', '11.0')`.

A construction may take multiple items, space delimited, e.g., `\u{+* .pizza}` (any character with a plus as a component and any character with "pizza" in the name).

Functions are in the TAN namespace, `tan:textalign.net,2015:ns`. The prefix `rgx` is suggested but not required. 

Other useful functions:
* `rgx:string-to-components()`. Takes each character in an input string and returns a concatenation of its decomposed components.
* `rgx:string-to-composites()`. Takes each character in an input string and returns a concatenation of characters that can decompose to that character.
* `rgx:string-base()`. Changes in an input string any characters that can decompose to a single base character.
* Key `get-chars-by-name`, e.g., `key('get-chars-by-name', ('parenthesis'), $default-ucd-names-db)`. Returns a tree fragment with Unicode characters with matching words in their names.
* `rgx:hex-to-dec()`. Converts hexadecimal numbers to decimal.
* `rgx:dec-to-hex()`. Converts decimal numbers to hexadecimal.
* `rgx:n-to-dec()`. Converts base-n systems (2 through 16, 64) to decimals.
* `rgx:dec-to-n()`. Converts decimals to any base-n system (as above). 

See the subdirectory `tests` for examples and 
[the XSLT function library](TAN-regex.xsl) for all the functions, with documentation. 

TAN-regex has been developed in service to the Text Alignment Network ([http://textalign.net](http://textalign.net)), but can be used independent of TAN. It is fully encapsulated in functions, so can be incorporated by any XSLT stylesheet via `<include>` or `<import>`.

For more on TAN-regex see Joel Kalvesmaki, “A New \u: Extending XPath Regular Expressions for Unicode.” *Proceedings of Balisage: The Markup Conference 2020. Balisage Series on Markup Technologies*, vol. 25 (2020). [https://doi.org/10.4242/BalisageVol25.Kalvesmaki01](https://doi.org/10.4242/BalisageVol25.Kalvesmaki01).
