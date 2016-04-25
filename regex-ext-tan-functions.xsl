<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs math xd tan fn tei functx" version="3.0">

    <xsl:function name="tan:matches" as="xs:boolean">
        <!-- two-param function of the three-param version below -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:copy-of select="tan:matches($input, $pattern, '')"/>
    </xsl:function>
    <xsl:function name="tan:matches" as="xs:boolean">
        <!-- Parallel to fn:matches(), but converts TAN-exceptions into classes. See tan:regex() for details. -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="flags" as="xs:string"/>
        <xsl:copy-of select="matches($input, tan:regex($pattern), $flags)"/>
    </xsl:function>
    <xsl:function name="tan:replace" as="xs:string">
        <!-- three-param function of the four-param version below -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="replacement" as="xs:string"/>
        <xsl:copy-of select="tan:replace($input, $pattern, $replacement, '')"/>
    </xsl:function>
    <xsl:function name="tan:replace" as="xs:string">
        <!-- Parallel to fn:replace(), but converts TAN-exceptions into classes. See tan:regex() for details. -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="replacement" as="xs:string"/>
        <xsl:param name="flags" as="xs:string"/>
        <xsl:copy-of select="replace($input, tan:regex($pattern), $replacement, $flags)"/>
    </xsl:function>
    <xsl:function name="tan:tokenize" as="xs:string*">
        <!-- two-param function of the three-param version below -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:copy-of select="tan:tokenize($input, $pattern, '')"/>
    </xsl:function>
    <xsl:function name="tan:tokenize" as="xs:string*">
        <!-- Parallel to fn:tokenize(), but converts TAN-exceptions into classes. See tan:regex() for details. -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="flags" as="xs:string"/>
        <xsl:copy-of select="tokenize($input, tan:regex($pattern), $flags)"/>
    </xsl:function>

    <xsl:function name="tan:regex" as="xs:string?">
        <!-- Input: string of a regex search
        Output: the same string, with TAN-reserved escape sequences replaced by characters class sequences
        E.g., '\k{.greek.capital.perispomeni}' - - > '[ἎἏἮἯἾἿὟὮὯᾎᾏᾞᾟᾮᾯ]'
        \k{.latin.cedilla} - - > '[ÇçĢģĶķĻļŅņŖŗŞşŢţȨȩᷗḈḉḐḑḜḝḨḩ]'
        'angle \k{4d-4f, 51}' - - > 'angle [MNOQ]'
        
        This function grabs entire classes of Unicode characters either by their codepoint or by the parts of 
        their name. It performs specially upon the form \k{***VALUE***}, where ***VALUE*** is either (1) one or
        more hexadecimal numbers joined by commas and hyphens or (2) one or more words each one prepended by a
        non-word character. In the first option, there will be returned every Unicode character that has been 
        picked, filling in ranges where indicated by the hyphen. In the second option, there will be returned 
        every Unicode character that has all of those words in its official Unicode name, or alias.
        Other examples:
        
          Any word with an omega, even if not in any of the Greek blocks: '\k{.omega}' (useful if you
          wish to find nonstandard uses of the omega, especially in the symbol block)
          
          Any word with two successive omegas, no matter their accentuation or capitalizaton, or if they 
          have an iota subscript: '\k{.greek.omega}{2}' (useful for looking up a Greek word where accentuation
          changes depending upon context or inflection)
          
          Every Greek word that attracts an accent from an enclitic: 
          '[\k{.greek.oxia}\k{.greek.tonos}\k{.greek.perispomeni}]\w*[\k{.greek.tonos}\k{.greek.oxia}]'
        -->
        <xsl:param name="regex" as="xs:string?"/>
        <xsl:variable name="tan-regex" select="doc('ucd/ucd-names.xml')"/>
        <xsl:variable name="esc-seq" select="'\\k\{([^\}]+)\}'"/>
        <xsl:variable name="pass-1">
            <regex>
                <xsl:analyze-string select="$regex" regex="{$esc-seq}">
                    <xsl:matching-substring>
                        <match>
                            <xsl:value-of
                                select="tan:process-regex-escape-k(regex-group(1), $tan-regex)"/>
                        </match>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <non-match>
                            <xsl:value-of select="."/>
                        </non-match>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </regex>
        </xsl:variable>
        <xsl:variable name="pass-2">
            <xsl:apply-templates select="$pass-1" mode="add-square-brackets"/>
        </xsl:variable>
        <xsl:value-of select="$pass-2//text()"/>
    </xsl:function>

    <xsl:function name="tan:process-regex-escape-k" as="xs:string?">
        <xsl:param name="val-inside-braces" as="xs:string"/>
        <xsl:param name="unicode-db" as="document-node()"/>
        <!-- characters used in the official character names -->
        <xsl:variable name="ucd-name-class" select="'[-#\(\)a-zA-Z0-9]'"/>
        <!-- characters allowed to separate items in a \k{} escape class -->
        <xsl:variable name="sep-class" select="'[^-#\)\(\w]'"/>
        <xsl:choose>
            <xsl:when
                test="matches($val-inside-braces, '^[0-9a-fA-F]{1,6}(\s*-\s*[0-9a-fA-F]{1,6})?(\s*,\s*[0-9a-fA-F]{1,6}(\s*-\s*[0-9a-fA-F]{1,6})?)*$')">
                <xsl:variable name="pass-1" as="xs:integer*">
                    <xsl:analyze-string select="$val-inside-braces" regex="\s*,\s*">
                        <xsl:non-matching-substring>
                            <xsl:variable name="range" select="tokenize(.,'\s*-\s*')"/>
                            <xsl:variable name="start" select="$range[1]"/>
                            <xsl:variable name="end" select="$range[2]"/>
                            <xsl:choose>
                                <xsl:when test="exists($end)">
                                    <xsl:copy-of select="for $i in (tan:hex-to-dec($start) to tan:hex-to-dec($end)) return $i"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="tan:hex-to-dec($start)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:value-of select="codepoints-to-string($pass-1[. gt 1])"/>
                <!--<xsl:analyze-string select="$val-inside-braces" regex="\s*,\s*">
                    <xsl:non-matching-substring>hi</xsl:non-matching-substring>
                </xsl:analyze-string>-->
            </xsl:when>
            <xsl:when
                test="matches($val-inside-braces, concat('^(', $sep-class, $ucd-name-class, '+)+$'))">
                <xsl:variable name="names-to-include" as="xs:string*">
                    <xsl:analyze-string select="$val-inside-braces"
                        regex="{concat(replace($sep-class,'\]','!]('),$ucd-name-class,'+)+')}">
                        <xsl:matching-substring>
                            <xsl:copy-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:variable name="names-to-exclude" as="xs:string*">
                    <xsl:analyze-string select="$val-inside-braces"
                        regex="{concat('!(',$ucd-name-class,'+)+')}">
                        <xsl:matching-substring>
                            <xsl:copy-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:variable name="pass-1"
                    select="
                        $unicode-db/*/*[every $i in $names-to-include
                            satisfies * = $i and not(some $j in $names-to-exclude
                                satisfies * = $j)]/@cp"/>
                <xsl:value-of
                    select="
                        codepoints-to-string(for $i in $pass-1
                        return
                            tan:hex-to-dec($i))"
                />
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:function>

    <xsl:mode name="add-square-brackets" on-no-match="shallow-copy"/>
    <xsl:template match="tan:match" name="prep-regex-char-class" mode="add-square-brackets">
        <xsl:variable name="preceding-text" as="xs:string?"
            select="string-join(preceding-sibling::tan:non-match/text(), '')"/>
        <xsl:variable name="preceding-text-without-escaped-backslashes" as="xs:string?"
            select="replace($preceding-text, '\\\\', '')"/>
        <xsl:variable name="preceding-text-without-escaped-brackets" as="xs:string?"
            select="replace($preceding-text-without-escaped-backslashes, '\\\[|\\\]', '')"/>
        <xsl:variable name="preceding-text-char-classes" as="element()">
            <char-classes>
                <xsl:analyze-string select="$preceding-text-without-escaped-brackets"
                    regex="\[[^\[]*">
                    <xsl:matching-substring>
                        <match>
                            <xsl:value-of select="."/>
                        </match>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <non-match>
                            <xsl:value-of select="."/>
                        </non-match>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </char-classes>
        </xsl:variable>
        <xsl:variable name="needs-brackets" as="xs:boolean"
            select="
                if (matches(($preceding-text-char-classes/*)[last()], '^\[[^\]]*$') or string-length(.) lt 1) then
                    false()
                else
                    true()"/>
        <xsl:copy>
            <xsl:value-of
                select="
                    if ($needs-brackets = true()) then
                        concat('[', ., ']')
                    else
                        ."
            />
        </xsl:copy>
    </xsl:template>

    <xsl:variable name="hex-key" as="xs:string+"
        select="
            '0',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            'A',
            'B',
            'C',
            'D',
            'E',
            'F'"/>
    <xsl:function name="tan:dec-to-hex" as="xs:string">
        <!-- Change any integer into a hexadecimal string
            Input: xs:integer 
         Output: hexadecimal equivalent as a string 
         E.g., 31 - > '1F'
      -->
        <xsl:param name="in" as="xs:integer"/>
        <xsl:sequence
            select="
                if ($in eq 0)
                then
                    '0'
                else
                    concat(if ($in gt 16)
                    then
                        tan:dec-to-hex($in idiv 16)
                    else
                        '',
                    $hex-key[($in mod 16) + 1])"
        />
    </xsl:function>

    <xsl:function name="tan:hex-to-dec" as="item()*">
        <!-- Change any hexadecimal string into an integer
         E.g., '1F' - > 31
      -->
        <xsl:param name="hex" as="xs:string?"/>
        <xsl:variable name="split" as="xs:integer*">
            <xsl:analyze-string select="$hex" regex="[0-9a-fA-F]">
                <xsl:matching-substring>
                    <xsl:copy-of select="index-of($hex-key, upper-case(.)) - 1"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="split-rev" select="reverse($split)"/>
        <!--<xsl:copy-of select="$split"/>-->
        <xsl:copy-of
            select="
                sum(for $i in (1 to count($split))
                return
                    $split-rev[$i]
                    * (xs:integer(math:pow(16, $i - 1))))"
        />
    </xsl:function>


</xsl:stylesheet>
