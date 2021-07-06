<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:rgx="tag:textalign.net,2015:ns" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="#all" version="3.0">
    
    <xsl:param name="rgx:cache-functions-available" as="xs:boolean" static="yes" select="system-property('xsl:supports-higher-order-functions') eq 'yes'"/>
    <xsl:param name="default-unicode-version" as="xs:double" select="13.0"/>
    
    <xsl:variable name="TAN-regex-version" as="xs:double" select="1.0"/>
    
    <xsl:variable name="unicode-versions-supported" as="xs:double+"
        select="5.1, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0"/>
    <xsl:function name="rgx:best-unicode-version" as="xs:double" visibility="public">
        <!-- Input: a double representing a Unicode version -->
        <!-- Output: the best version supported -->
        <xsl:param name="version" as="xs:double?"/>
        <xsl:choose>
            <xsl:when test="$version = $unicode-versions-supported">
                <xsl:sequence select="$version"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="version-just-before" select="max($unicode-versions-supported[. lt $version])"/>
                <xsl:variable name="version-just-after" select="min($unicode-versions-supported[. gt $version])"/>
                <xsl:variable name="next-best-version" select="($version-just-before, $version-just-after, $default-unicode-version)[1]"/>
                <xsl:message select="'Version ' || string($version) || ' of Unicode not supported. Using version ' || string($next-best-version) || '.'"/>
                <xsl:sequence select="$next-best-version"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- this is a regular expression pattern for characters in a string that should be prefaced with \ when converting to a regular expression -->
    <xsl:variable name="characters-to-escape-when-converting-string-to-regex" as="xs:string"
        select="'[\.\[\]\\\|\^\$\?\*\+\{\}\(\)]'"/>
    <!-- this is a regular expression pattern to find specially escaped characters in a string that is a regular 
        expression. It looks for the escape character \ followed by special punctuation .[]\|^$?*+{}() or by 
        individual letters or digits or a pPu with {} -->
    <xsl:variable name="escapes-in-regex" as="xs:string"
        select="'\\[\.\[\]\\\|\^\$\?\*\+\{\}\(\)nrtdDsSiIcCwW\d]|\\[pPu]\{[^\}]*\}'"/>
    <xsl:variable name="open-group-symbols-regex">[\[\(\{]</xsl:variable>
    <xsl:variable name="close-group-symbols-regex">[\]\)\}]</xsl:variable>

    <!-- characters used to delimit items within \u{}, currently the space -->
    <xsl:variable name="u-item-delimiter-regex" select="' '"/>
    <!-- characters used in the official Unicode character names -->
    <xsl:variable name="characters-allowed-in-ucd-names-regex" select="'[-#\(\)a-zA-Z0-9]'"/>
    <!-- characters used to chain Unicode character name words within a {} escape class, currently restricted to . and ! -->
    <xsl:variable name="name-marker-regex" select="'[\.!]'"/>
    <!-- character used to signal the start of a string that should be expanded into all composite forms -->
    <xsl:variable name="composite-marker-regex" select="'\+'"/>
    <!-- character used to signal the start of a string that should be reduced to the string base form -->
    <xsl:variable name="base-marker-regex" select="'-'"/>
    
    <xsl:function name="rgx:escape" as="xs:string*" visibility="public">
        <!-- Input: any sequence of strings -->
        <!-- Output: each string prepared for regular expression searches, i.e., with reserved characters escaped out. -->
        <xsl:param name="strings" as="xs:string*"/>
        <xsl:sequence
            select="
                for $i in $strings
                return
                    replace($i, ('(' || $characters-to-escape-when-converting-string-to-regex || ')'), '\\$1')"
        />
    </xsl:function>
    
    <xsl:function name="rgx:parse-flags" as="element()" visibility="private">
        <!-- Input: a string corresponding to a $flags parameter in a regular expression function -->
        <!-- Output: an element that differentiates parts of the string between special TAN-regex flags and not -->
        <xsl:param name="flags" as="xs:string"/>
        <flags>
            <xsl:analyze-string select="$flags" regex="\d+\.\d+">
                <xsl:matching-substring>
                    <xsl:variable name="this-unicode-version" select="xs:double(.)"/>
                    <u>
                        <xsl:value-of select="rgx:best-unicode-version($this-unicode-version)"/>
                    </u>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <standard>
                        <xsl:value-of select="."/>
                    </standard>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </flags>
    </xsl:function>

    <xsl:function name="rgx:matches" as="xs:boolean" visibility="public">
        <!-- two-param function of the three-param version below -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:sequence select="rgx:matches($input, $pattern, '')"/>
    </xsl:function>
    <xsl:function name="rgx:matches" as="xs:boolean" visibility="public">
        <!-- Parallel to fn:matches(), but converts \u{} into classes. See rgx:regex() for details. -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="flags" as="xs:string"/>
        <xsl:variable name="flags-parsed" select="rgx:parse-flags($flags)"/>
        <xsl:variable name="version-picked" select="xs:double($flags-parsed/rgx:u[1])"/>
        <xsl:variable name="flags-norm" select="string-join($flags-parsed/rgx:standard)"/>
        <xsl:if test="count($flags-parsed/rgx:u) gt 1">
            <xsl:message
                select="string(count($flags-parsed/rgx:u)) || ' Unicode versions specified. Using only the first found.'"
            />
        </xsl:if>
        <xsl:sequence select="matches($input, rgx:regex($pattern, ($version-picked, $default-unicode-version)[1]), $flags-norm)"/>
    </xsl:function>
    
    <xsl:function name="rgx:replace" as="xs:string" visibility="public">
        <!-- three-param function of the four-param version below -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="replacement" as="xs:string"/>
        <xsl:sequence select="rgx:replace($input, $pattern, $replacement, '')"/>
    </xsl:function>
    <xsl:function name="rgx:replace" as="xs:string" visibility="public">
        <!-- Parallel to fn:replace(), but converts \u{} into classes. See rgx:regex() for details. -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="replacement" as="xs:string"/>
        <xsl:param name="flags" as="xs:string"/>
        <xsl:variable name="flags-parsed" select="rgx:parse-flags($flags)"/>
        <xsl:variable name="version-picked" select="xs:double($flags-parsed/rgx:u[1])"/>
        <xsl:variable name="flags-norm" select="string-join($flags-parsed/rgx:standard)"/>
        <xsl:if test="count($flags-parsed/rgx:u) gt 1">
            <xsl:message
                select="string(count($flags-parsed/rgx:u)) || ' Unicode versions specified. Using only the first found.'"
            />
        </xsl:if>
        <xsl:sequence select="replace($input, rgx:regex($pattern, ($version-picked, $default-unicode-version)[1]), $replacement, $flags-norm)"/>
    </xsl:function>
    
    <xsl:function name="rgx:tokenize" as="xs:string*" visibility="public">
        <!-- two-param function of the three-param version below -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:sequence select="rgx:tokenize($input, $pattern, '')"/>
    </xsl:function>
    <xsl:function name="rgx:tokenize" as="xs:string*" visibility="public">
        <!-- Parallel to fn:tokenize(), but converts \u{} into classes. See rgx:regex() for details. -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="flags" as="xs:string"/>
        <xsl:variable name="flags-parsed" select="rgx:parse-flags($flags)"/>
        <xsl:variable name="version-picked" select="xs:double($flags-parsed/rgx:u[1])"/>
        <xsl:variable name="flags-norm" select="string-join($flags-parsed/rgx:standard)"/>
        <xsl:if test="count($flags-parsed/rgx:u) gt 1">
            <xsl:message
                select="string(count($flags-parsed/rgx:u)) || ' Unicode versions specified. Using only the first found.'"
            />
        </xsl:if>
        <xsl:sequence select="tokenize($input, rgx:regex($pattern, ($version-picked, $default-unicode-version)[1]), $flags-norm)"/>
    </xsl:function>
    
    <xsl:function name="rgx:analyze-string" as="element()" visibility="public">
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:sequence select="rgx:analyze-string($input, $pattern, '')"/>
    </xsl:function>
    <xsl:function name="rgx:analyze-string" as="element()" visibility="public">
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="pattern" as="xs:string"/>
        <xsl:param name="flags" as="xs:string"/>
        <xsl:variable name="flags-parsed" select="rgx:parse-flags($flags)"/>
        <xsl:variable name="version-picked" select="xs:double($flags-parsed/rgx:u[1])"/>
        <xsl:variable name="flags-norm" select="string-join($flags-parsed/rgx:standard)"/>
        <xsl:if test="count($flags-parsed/rgx:u) gt 1">
            <xsl:message
                select="string(count($flags-parsed/rgx:u)) || ' Unicode versions specified. Using only the first found.'"
            />
        </xsl:if>
        <xsl:sequence
            select="analyze-string($input, rgx:regex($pattern, ($version-picked, $default-unicode-version)[1]), $flags-norm)"
        />
    </xsl:function>
    
    
    <xsl:variable name="default-ucd-decomp-db" select="rgx:get-ucd-decomp-db()"/>
    <xsl:function name="rgx:get-ucd-decomp-db" visibility="private">
        <!-- one-parameter version of fuller one below -->
        <xsl:sequence select="rgx:get-ucd-decomp-db($default-unicode-version)"/>
    </xsl:function>
    <xsl:function name="rgx:get-ucd-decomp-db" visibility="private">
        <!-- Input: a double specifying a Unicode version number -->
        <!-- Output: the document that contains the data for decomposing characters to and from 
            their parts -->
        <xsl:param name="version" as="xs:double"/>
        <xsl:sequence
            select="doc('ucd/ucd-decomp.' || format-number(rgx:best-unicode-version($version), '0.0') || '.xml')"
        />
    </xsl:function>
    
    <xsl:variable name="default-ucd-decomp-simple-db" select="rgx:get-ucd-decomp-simple-db()"/>
    <xsl:function name="rgx:get-ucd-decomp-simple-db" visibility="private">
        <!-- one-parameter version of fuller one below -->
        <xsl:sequence select="rgx:get-ucd-decomp-simple-db($default-unicode-version)"/>
    </xsl:function>
    <xsl:function name="rgx:get-ucd-decomp-simple-db" visibility="private">
        <!-- Input: a double specifying a Unicode version number -->
        <!-- Output: the document that contains the data for translating characters to and from 
            their base characters -->
        <xsl:param name="version" as="xs:double"/>
        <xsl:sequence
            select="doc('ucd/ucd-decomp-simple.' || format-number(rgx:best-unicode-version($version), '0.0') || '.xml')"
        />
    </xsl:function>
    
    <xsl:variable name="default-ucd-names-db" select="rgx:get-ucd-names-db()"/>
    <xsl:function name="rgx:get-ucd-names-db" visibility="private">
        <!-- zero-parameter version of fuller one below -->
        <xsl:sequence select="rgx:get-ucd-names-db($default-unicode-version)"/>
    </xsl:function>
    <xsl:function name="rgx:get-ucd-names-db" visibility="private">
        <!-- Input: a double specifying a Unicode version number -->
        <!-- Output: the document that contains the data for Unicode character names -->
        <xsl:param name="version" as="xs:double"/>
        <xsl:sequence
            select="doc('ucd/ucd-names.' || format-number(rgx:best-unicode-version($version), '0.0') || '.xml')"
        />
    </xsl:function>
    
    
    <xsl:function name="rgx:string-base" as="xs:string?" visibility="public">
        <!-- one-param version of the fuller one, below -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:sequence select="rgx:string-base($arg, $default-unicode-version)"/>
    </xsl:function>
    <xsl:function name="rgx:string-base" as="xs:string?" visibility="public">
        <!-- This function takes any string and replaces every character with its base Unicode character.
      This function is useful to prepare a text to be searched without respect to accents.
      E.g., ἄνθρωπός - > ανθρωπος
      Note, the ς is retained because it doesn't decompose. To match on σ one needs to use the flag 'i' (case insensitive)
      because ς case-folds to σ.
      This function is similar to rgx:string-to-components(), but strictly enforces a one-for-one replacement,
      so that it behaves much like fn:lower-case() and fn:upper-case(), where the string length is always preserved.
      To this end, this function is based on fn:translate(), and uses simple decomposition databases, which are much 
      smaller and quicker to use than are full decomposition databases.
      The strict one-for-one replacement observes the following rules:
          If a character decomposes to a single character, that single character is returned.
          If a character decomposes to multiple characters that are identical, that single character is returned, e.g., ‴ to ′
          If a character decomposes to multiple characters, a distinction is made between base and non-base characters:
          - Base characters: \p{Lu}\p{Ll}\p{Lt}\p{Lo}\p{N}\p{S}
          - Non-base characters: \p{Lm}\p{M}\p{P}\p{Z}\p{C}
          If after non-base characters are removed there is not exactly one unique decomposed character left, the original input is retained.
        The above rules are already reflected in the contents of the simple decomposition database, so do not need to be 
        expressed in this function. For more, see ucd/ucd-decomp.xsl. -->

        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="version" as="xs:double"/>
        <xsl:variable name="this-simple-decomp-db" select="rgx:get-ucd-decomp-simple-db($version)"/>
        <xsl:value-of
            select="translate($arg, $this-simple-decomp-db/rgx:translate/rgx:mapString, $this-simple-decomp-db/rgx:translate/rgx:transString)"
        />
    </xsl:function>
    
    <xsl:function name="rgx:string-to-components" as="xs:string*" visibility="public">
        <!-- one-param version of the fuller one, below -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:sequence select="rgx:string-to-components($arg, $default-unicode-version)"/>
    </xsl:function>
    <xsl:function name="rgx:string-to-components" as="xs:string*" visibility="public">
        <!-- Input: any string; a Unicode version number. -->
        <!-- Output: one string per character in the input; if a character lends itself to decomposition, its component parts are 
        returned, otherwise the character itself is returned. -->
        <!-- This function is the inverse of rgx:string-to-composites(). -->
        <!-- If you wish to have more control over which components are returned (e.g., exclusion of combining marks), consider
        using either rgx:string-base() or the database directly: rgx:get-ucd-decomp-db(). The each rgx:char/rgx:b has @gc
        with the code for the component's general category -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="version" as="xs:double"/>
        <xsl:variable name="this-data-source"
            select="
                if ($version eq $default-unicode-version) then
                    $default-ucd-decomp-db
                else
                    rgx:get-ucd-decomp-db($version)"
        />
        <xsl:analyze-string select="$arg" regex=".">
            <xsl:matching-substring>
                <xsl:variable name="this-char" select="."/>
                <xsl:variable name="this-decomp-entry" select="$this-data-source/*/rgx:char[@val = $this-char]"/>
                <xsl:value-of
                    select="
                        if (exists($this-decomp-entry)) then
                            string-join($this-decomp-entry/rgx:b)
                        else
                            $this-char"
                />
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="rgx:string-to-composites" as="xs:string*" visibility="public">
        <!-- one-parameter version of fuller one, below -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:sequence select="rgx:string-to-composites($arg, $default-unicode-version)"/>
    </xsl:function>
    <xsl:function name="rgx:string-to-composites" as="xs:string*" visibility="public">
        <!-- Input: a string; a version of Unicode (double) -->
        <!-- Output: one string per character in the input; that string consists of the character itself 
            followed by all characters that use it as a base -->
        <!-- This function is the inverse of rgx:string-to-components. 
         E.g., 'Max' - > 'MᴹḾṀṂℳⅯⓂ㎆㎒㎫㎹㎿㏁Ｍ𝐌𝑀𝑴𝓜𝔐𝕄𝕸𝖬𝗠𝘔𝙈𝙼🄼🅋🅪🅫aªàáâãäåāăąǎǟǡǻȁȃȧᵃḁẚạảấầẩẫậắằẳẵặₐ℀℁ⓐ㏂ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊xˣẋẍₓⅹⅺⅻⓧｘ𝐱𝑥𝒙𝓍𝔁𝔵𝕩𝖝𝗑𝘅𝘹𝙭𝚡'
         This is useful for preparing regex character classes to broaden a search. 
      -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="version" as="xs:double"/>
        <xsl:variable name="this-data-source" as="document-node()"
            select="
                if ($version = $default-unicode-version) then
                    $default-ucd-decomp-db
                else
                    rgx:get-ucd-decomp-db($version)"
        />
        <xsl:analyze-string select="$arg" regex=".">
            <xsl:matching-substring>
                <xsl:variable name="this-char" select="."/>
                <xsl:variable name="this-match"
                    select="$this-data-source/*/rgx:char[rgx:b = $this-char]"/>
                <xsl:sequence select="$this-char || (string-join($this-match/@val))"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <xsl:function name="rgx:codepoints-to-string" as="xs:string?" visibility="public">
        <!-- one-parameter function for the one below; default XML 1.0 -->
        <xsl:param name="arg" as="xs:integer*"/>
        <xsl:sequence select="rgx:codepoints-to-string($arg, true())"/>
    </xsl:function>
    <xsl:function name="rgx:codepoints-to-string" as="xs:string?" visibility="public">
        <!-- Input: any number of integers -->
        <!-- Output: the string value representation, but only if the integers represent valid characters in XML -->
        <!-- Like fn:codepoints-to-string(), but filters out XML illegal characters -->
        <xsl:param name="arg" as="xs:integer*"/>
        <xsl:param name="xml-1-0" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="$xml-1-0">
                <xsl:sequence
                    select="codepoints-to-string($arg[. = (9, 10, 13) or (. ge 32 and . le 65533) or (. ge 65536 and . le 1114109)])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence
                    select="codepoints-to-string($arg[(. ge 1 and . le 65533) or (. ge 65536 and . le 1114109)])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="rgx:process-regex-escape-u" as="xs:string?" visibility="private">
        <!-- one-parameter version of fuller one, below -->
        <xsl:param name="val-inside-braces" as="xs:string"/>
        <xsl:sequence select="rgx:process-regex-escape-u($val-inside-braces, $default-unicode-version)"/>
    </xsl:function>
    <xsl:function name="rgx:process-regex-escape-u" as="xs:string?" visibility="private">
        <!-- Input: a string that is inside the braces of a \u{} expression -->
        <!-- Output: the expansion of the expression -->
        <!-- Acceptable contents of \u{}: -->
        <!-- 1. Individual hex values or ranges of them, separated by a comma or space. Values will be replaced with entities -->
        <!-- '4d-4f, 51' > '&#x4d;-&#x4f;&#x51;' -->
        <!-- 2. Composite signal: + followed by a string -->
        <!-- '+b' > 'bᵇḃḅḇ⒝ⓑ㍴㏔㏝ｂ𝐛𝑏𝒃𝒷𝓫𝔟𝕓𝖇𝖻𝗯𝘣𝙗𝚋' -->
        <!-- 3. Base signal: - followed by a string -->
        <!-- '-ḉ' > 'c' -->
        <!-- 4. name keywords: chains of . or ! each followed by a string -->
        <!-- '.greek.capital.perispomeni' > 'ἎἏἮἯἾἿὟὮὯᾎᾏᾞᾟᾮᾯ'
        .latin.cedilla - - > 'ÇçĢģĶķĻļŅņŖŗŞşŢţȨȩᷗḈḉḐḑḜḝḨḩ'
        .m!small - - > 'MƜൔᒻᒼᒾᒿᛗᛘᛙᣘᧄᮿᰮᴹḾṀṂℳⓂⱮㄇ㎛㎡㎥㎧㎨㏁㏞㏟ꚳꟽꟿꩌＭ'  -->

        <xsl:param name="val-inside-braces" as="xs:string"/>
        <xsl:param name="version" as="xs:double"/>
        
        <!-- first normalize spacing around the hyphen and comma, then tokenize on spaces -->
        <xsl:variable name="val-normalized" select="normalize-space($val-inside-braces)"/>
        <xsl:variable name="val-parts" as="xs:string*" select="tokenize($val-normalized, $u-item-delimiter-regex)"/>
        <xsl:variable name="val-parts-analyzed" as="xs:string*">
            <xsl:for-each select="$val-parts">
                <xsl:choose>
                    <xsl:when test="matches(., '^[0-9a-fA-F]{1,6}(-[0-9a-fA-F]{1,6})?$')">
                        <!-- it's a Unicode codepoint -->
                        <xsl:analyze-string select="." regex="[0-9a-fA-F]+">
                            <xsl:matching-substring>
                                <xsl:sequence select="rgx:codepoints-to-string(rgx:hex-to-dec-rgx(.))"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <!-- keep the hyphen -->
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                    <xsl:when test="matches(., '^' || $composite-marker-regex)">
                        <xsl:variable name="text-to-expand" select="replace(., '^' || $composite-marker-regex, '')"/>
                        <xsl:value-of
                            select="string-join(rgx:string-to-composites($text-to-expand, $version))"/>
                    </xsl:when>
                    <xsl:when test="matches(., '^' || $base-marker-regex)">
                        <xsl:variable name="text-to-reduce" select="replace(., '^' || $base-marker-regex, '')"/>
                        <xsl:variable name="this-text-as-base" select="rgx:string-base($text-to-reduce, $version)"/>
                        <xsl:variable name="unique-codepoints" select="distinct-values(string-to-codepoints($this-text-as-base))"/>
                        <xsl:value-of
                            select="string-join(codepoints-to-string($unique-codepoints))"/>
                    </xsl:when>
                    <xsl:when test="matches(., ('^(' || $name-marker-regex || $characters-allowed-in-ucd-names-regex || '+)+$'))">
                        <xsl:variable name="ucd-name-analyzed" as="element()">
                            <analysis>
                                <xsl:analyze-string select="."
                                    regex="{'(' ||$name-marker-regex || ')(' ||$characters-allowed-in-ucd-names-regex || '+)'}">
                                    <xsl:matching-substring>
                                        <xsl:choose>
                                            <xsl:when test="regex-group(1) = '.'">
                                                <include>
                                                  <xsl:value-of select="regex-group(2)"/>
                                                </include>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <exclude>
                                                  <xsl:value-of select="regex-group(2)"/>
                                                </exclude>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:matching-substring>
                                </xsl:analyze-string>
                            </analysis>
                        </xsl:variable>
                        <xsl:variable name="chars-found"
                            select="rgx:get-chars-by-name($ucd-name-analyzed/rgx:include, $ucd-name-analyzed/rgx:exclude, $version)"/>
                        <xsl:sequence select="string-join($chars-found/@val)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message
                            select="'Malformed \u{} expression ' || . || '. The expression in braces should be (1) hex values/ranges; (2) words in unicode character names prepended by . or !; or (3) a string prepended by + or - (expansion to composite form or reduction to base form of following string)'"
                            terminate="yes"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($val-parts-analyzed, '')"/>
    </xsl:function>

    <xsl:key name="get-chars-by-name" match="rgx:char" use="*/rgx:n"/>
    <xsl:function name="rgx:get-chars-by-name" visibility="private" _cache="{$rgx:cache-functions-available}">
        <!-- Input: two sets of strings -->
        <!-- Output: <char> elements from the Unicode database, the words of whose name (or alias) match all the first set and none of the second -->
        <xsl:param name="words-in-name" as="xs:string*"/>
        <xsl:param name="words-not-in-name" as="xs:string*"/>
        <xsl:param name="version" as="xs:double"/>
        <xsl:variable name="words-in-name-norm"
            select="
                for $i in $words-in-name
                return
                    lower-case($i)"
        />
        <xsl:variable name="words-not-in-name-norm"
            select="
                for $i in $words-not-in-name
                return
                    lower-case($i)"
        />
        <xsl:variable name="unicode-names-db"
            select="
                if ($version = $default-unicode-version) then
                    $default-ucd-names-db
                else
                    rgx:get-ucd-names-db($version)"
        />
        <xsl:sequence
            select="
                $unicode-names-db/rgx:ucd/rgx:char[*[every $i in $words-in-name-norm
                    satisfies * = $i and not(some $j in $words-not-in-name-norm
                        satisfies * = $j)]]"
        />
    </xsl:function>
    
    <xsl:function name="rgx:build-char-replacement-guide" as="element()" visibility="private">
        <!-- Input: three sequences of strings; a boolean (whether matches should be strict); a double (Unicode version) -->
        <!-- Output: an XML tree rgx:replace/rgx:char/rgx:with specifying that every rgx:char/@val should be replaced
            by a string-joining of its rgx:with/@val. -->
        <!-- This function should be used to optimize replacement through a global variable. See documentation at 
            rgx:replace-by-char-name(), which this function supports.  -->
        <xsl:param name="words-in-name-to-drop" as="xs:string*"/>
        <xsl:param name="words-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="words-not-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="search-is-strict" as="xs:boolean?"/>
        <xsl:param name="version" as="xs:double"/>
        <xsl:variable name="unicode-names-db"
            select="
                if ($version = $default-unicode-version) then
                    $default-ucd-names-db
                else
                    rgx:get-ucd-names-db($version)"
        />
        <xsl:variable name="p1-norm"
            select="
                for $i in $words-in-name-to-drop
                return
                    lower-case($i)"
        />
        <xsl:variable name="p2-norm"
            select="
                for $i in $words-in-replacement-char-name
                return
                    lower-case($i)"
        />
        <xsl:variable name="p3-norm"
            select="
                for $i in $words-not-in-replacement-char-name
                return
                    lower-case($i)"
        />
        <xsl:variable name="relevant-db-entries" select="$unicode-names-db/rgx:ucd/rgx:char[*/* = $p1-norm]"/>
        <replace>
            <xsl:for-each select="$relevant-db-entries">
                <xsl:variable name="this-na-or-alias" select="*[rgx:n = $p1-norm]"/>
                <xsl:variable name="these-name-words" select="$this-na-or-alias/rgx:n[not(. = $p1-norm)]"/>
                <xsl:variable name="replacements"
                    select="rgx:get-chars-by-name(($these-name-words, $p2-norm), $p3-norm, $version)"/>
                <xsl:variable name="replacements-culled"
                    select="
                        if ($search-is-strict = true()) then
                            $replacements[*[every $i in rgx:n
                                satisfies $i = ($these-name-words, $words-in-replacement-char-name)]]
                        else
                            $replacements"
                />
                <xsl:if test="exists($replacements-culled)">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:for-each select="$replacements-culled">
                            <with>
                                <xsl:copy-of select="@*"/>
                            </with>
                        </xsl:for-each>
                    </xsl:copy>
                </xsl:if>
            </xsl:for-each>
        </replace>
    </xsl:function>

    <xsl:function name="rgx:replace-by-char-name" as="xs:string?" visibility="public">
        <!-- five-parameter version of the full function, below -->
        <xsl:param name="string-to-replace" as="xs:string?"/>
        <xsl:param name="words-in-name-to-drop" as="xs:string*"/>
        <xsl:param name="words-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="words-not-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="search-is-strict" as="xs:boolean?"/>
        <xsl:sequence
            select="rgx:replace-by-char-name($string-to-replace, $words-in-name-to-drop, $words-in-replacement-char-name, $words-not-in-replacement-char-name, $search-is-strict, $default-unicode-version)"
        />
    </xsl:function>
    <xsl:function name="rgx:replace-by-char-name" as="xs:string?" visibility="public">
        <!-- six-parameter version of the full function, below -->
        <xsl:param name="string-to-replace" as="xs:string?"/>
        <xsl:param name="words-in-name-to-drop" as="xs:string*"/>
        <xsl:param name="words-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="words-not-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="search-is-strict" as="xs:boolean?"/>
        <xsl:param name="version" as="xs:double"/>
        <xsl:variable name="this-replace-guide" as="element()"
            select="rgx:build-char-replacement-guide($words-in-name-to-drop, $words-in-replacement-char-name, $words-not-in-replacement-char-name, $search-is-strict, $version)"/>
        
        <xsl:sequence
            select="rgx:replace-by-char-name($string-to-replace, $this-replace-guide)"
        />
    </xsl:function>

    <xsl:function name="rgx:replace-by-char-name" as="xs:string?" visibility="private">
        <!-- Input: a string to be changed; three sets of strings; a boolean -->
        <!-- Output: the string with characters replaced according to the rules below -->
        <!-- This function was written primarily to transform Greek letters, e.g., to change graves into acutes -->
        <!-- The input string is broken into individual characters. Focus is placed on only those characters whose Unicode name 
            has words matching $words-in-name-to-drop. Other words in the first matching name are retained, and a search is made
            for any other Unicode character that has names specified by $words-in-replacement-char-name and does
            not have words specified by $words-not-in-replacement-char-name. -->
        <!-- If the boolean is false, then the search will return Unicode codepoints that might have other 
            words in their name; otherwise the match must correspond to all words in the target name. -->
        <!-- If the character does not have an entry in the $replace-guide, the original
            character is returned. -->
        <!-- The process will be applied to a char against only the first name found, not aliases. -->
        <!-- To use this function optimally, first bind the second parameter to a global variable, using rgx:build-char-replacement-guide(),
        then use the 2-parameter version of this function. -->
        <xsl:param name="string-to-replace" as="xs:string?"/>
        <xsl:param name="replace-guide" as="element(rgx:replace)"/>
        
        <xsl:variable name="these-cps" select="string-to-codepoints($string-to-replace)"/>
        <xsl:variable name="output" as="xs:string*">
            <xsl:for-each select="$these-cps">
                <xsl:variable name="this-val" select="codepoints-to-string(.)"/>
                <xsl:variable name="this-entry" select="$replace-guide/rgx:char[@val = $this-val]"/>
                <xsl:choose>
                    <xsl:when test="exists($this-entry)">
                        <xsl:value-of select="string-join($this-entry/rgx:with/@val)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$this-val"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="string-join($output)"/>
    </xsl:function>

    <xsl:function name="rgx:regex" as="xs:string?" visibility="private">
        <!-- one-parameter version of the longer one, below -->
        <xsl:param name="regex" as="xs:string?"/>
        <xsl:sequence select="rgx:regex($regex, $default-unicode-version)"/>
    </xsl:function>

    <xsl:function name="rgx:regex" as="xs:string?" _cache="{$rgx:cache-functions-available}" visibility="private">
        <!-- Input: string representing a regex pattern -->
        <!-- Output: the regular expression adjusted according to TAN-regex rules -->
        <xsl:param name="regex" as="xs:string?"/>
        <xsl:param name="version" as="xs:double"/>
        <xsl:choose>
            <xsl:when test="matches($regex, '\\u')">
                <xsl:value-of select="rgx:parse-regex($regex, $version)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$regex"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="rgx:parse-regex" as="element()" _cache="{$rgx:cache-functions-available}" visibility="private">
        <!-- Input: a regular expression -->
        <!-- Output: an element with the regular expression parsed -->
        <!-- Any errors are embedded as <error>s -->
        <xsl:param name="regex" as="xs:string?"/>
        <xsl:param name="version" as="xs:double"/>
        <!-- Step 1: isolate all escaped characters, parentheses, brackets, braces, marking the rest as regular text -->
        <xsl:variable name="regex-parts-parsed" as="element()">
            <regex>
                <xsl:analyze-string select="$regex" regex="{$escapes-in-regex}">
                    <xsl:matching-substring>
                        <escape class="{substring(.,2,1)}">
                            <xsl:value-of select="."/>
                        </escape>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="{$open-group-symbols-regex}">
                            <xsl:matching-substring>
                                <open class="{.}">
                                    <xsl:value-of select="."/>
                                </open>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:analyze-string select="." regex="{$close-group-symbols-regex}">
                                    <xsl:matching-substring>
                                        <close class="{translate(., '])}', '[({')}">
                                            <xsl:value-of select="."/>
                                        </close>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:if test="matches(., '\\')">
                                            <error message="illegal escape character, \"/>
                                        </xsl:if>
                                        <regular>
                                            <xsl:value-of select="."/>
                                        </regular>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </regex>
        </xsl:variable>
        <xsl:variable name="regex-parts-count" select="count($regex-parts-parsed/*)"/>
        <!-- Step 2: check opening and closing group tags, and parse \u{}. We add @level information
        in case users of this function wish to analyze a parsed regular expression. -->
        <xsl:variable name="results" as="element()">
            <results>
                <xsl:iterate select="$regex-parts-parsed/*">
                    <!-- Any new unclose group gets put at the head of the sequence $unclosed-groups -->
                    <xsl:param name="unclosed-groups" as="xs:string*"/>
                    <xsl:variable name="this-item-name" select="name(.)"/>
                    <xsl:variable name="this-is-last-item" select="position() eq $regex-parts-count"/>
                    <xsl:variable name="this-opens-group" select="$this-item-name = 'open'"/>
                    <xsl:variable name="this-closes-group" select="$this-item-name = 'close'"/>
                    <xsl:variable name="is-escape-u" select="@class = 'u'"/>
                    <xsl:variable name="new-unclosed-groups" as="xs:string*"
                        select="
                            if ($this-closes-group) then
                                $unclosed-groups[position() gt 1]
                            else
                                if ($this-opens-group) then
                                    (@class, $unclosed-groups)
                                else
                                    $unclosed-groups"
                    />
                    <xsl:variable name="this-level"
                        select="
                            if ($this-opens-group) then
                                (count($unclosed-groups) + 1)
                            else
                                count($unclosed-groups)"
                    />
                    
                    <xsl:if test="$this-closes-group and not(@class eq $unclosed-groups[1])">
                        <error message="closing group tag {@class} does not match last unclosed group marker {$unclosed-groups[1]}"/>
                    </xsl:if>
                    <xsl:if test="$this-opens-group and ($unclosed-groups[1] = ('[', '{'))">
                        <error message="group {$unclosed-groups[1]} cannot take a nested group"/>
                    </xsl:if>
                    <xsl:if test="$this-is-last-item and count($new-unclosed-groups) gt 0">
                        <error
                            message="Regular expression has {count($new-unclosed-groups)} unclosed groups {string-join(reverse($new-unclosed-groups), ' ')}"
                        />
                    </xsl:if>
                    <xsl:choose>
                        <xsl:when test="$is-escape-u">
                            <xsl:variable name="this-value"
                                select="replace(., '\\u\{([^{]*)\}', '$1')"/>
                            <xsl:variable name="this-u-analyzed"
                                select="rgx:process-regex-escape-u($this-value, $version)"/>
                            <xsl:variable name="is-in-char-class" select="$unclosed-groups[1] eq '['"/>
                            <xsl:if test="$unclosed-groups[1] eq '{'">
                                <error message="\u may not be placed inside curly brackets"/>
                            </xsl:if>
                            <!-- If not already inside a [-based character class, wrap the results in square brackets -->
                            <xsl:if test="not($is-in-char-class)">
                                <open class="[" level="{$this-level + 1}">[</open>
                            </xsl:if>
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:attribute name="level"
                                    select="
                                        if (not($is-in-char-class)) then
                                            ($this-level + 1)
                                        else
                                            $this-level"
                                />
                                <xsl:value-of select="$this-u-analyzed"/>
                            </xsl:copy>
                            <xsl:if test="not($is-in-char-class)">
                                <close class="[" level="{$this-level + 1}">]</close>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:attribute name="level" select="$this-level"/>
                                <xsl:value-of select="."/>
                            </xsl:copy>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:next-iteration>
                        <xsl:with-param name="unclosed-groups" select="$new-unclosed-groups"/>
                    </xsl:next-iteration>
                </xsl:iterate>
            </results>
        </xsl:variable>
        <xsl:sequence select="$results"/>
    </xsl:function>
    
    <xsl:function name="rgx:regex-is-valid" as="xs:boolean" visibility="public">
        <!-- Input: a string -->
        <!-- Output: true if the string is a valid regular expression, false otherwise -->
        <xsl:param name="input-regex" as="xs:string?"/>
        <xsl:try select="exists($input-regex) and rgx:matches('A', 'A|' || $input-regex)">
            <xsl:catch>
                <xsl:value-of select="false()"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    
    <xsl:function name="rgx:hex-to-dec-rgx" as="xs:integer?" visibility="private">
        <!-- Input: a string representing a hexadecimal number -->
        <!-- Output: the integer value, e.g., '1F' - > 31 -->
        <xsl:param name="hex" as="xs:string?"/>
        <xsl:variable name="hex-key" as="xs:string+"
            select="('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')"/>
        <xsl:variable name="split" as="xs:integer*">
            <xsl:analyze-string select="$hex" regex="[0-9a-fA-F]">
                <xsl:matching-substring>
                    <xsl:copy-of select="index-of($hex-key, upper-case(.)) - 1"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="split-rev" select="reverse($split)"/>
        <xsl:copy-of
            select="
                sum(for $i in (1 to count($split))
                return
                    $split-rev[$i]
                    * (xs:integer(math:pow(16, $i - 1))))"
        />
    </xsl:function>

</xsl:stylesheet>
