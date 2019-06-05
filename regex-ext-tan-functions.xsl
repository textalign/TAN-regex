<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:tan-regex="tag:textalign.net,2015:regex:ns"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
    exclude-result-prefixes="#all" version="2.0">

    <xsl:variable name="esc-seq" select="'\\u\{?([^\}]*)\}?'"/>
    <xsl:variable name="unicode-db" select="doc('ucd/ucd-names.xml')"/>

    <!-- this is a regular expression pattern for characters in a string that should be prefaced with \ when converting to a regular expression -->
    <xsl:variable name="characters-to-escape-when-converting-string-to-regex" as="xs:string"
        select="'[\.\[\]\\\|\^\$\?\*\+\{\}\(\)]'"/>
    <!-- this is a regular expression pattern to find specially escaped characters in a string that is a regular expression -->
    <xsl:variable name="escapes-in-regex" as="xs:string"
        select="'\\[\.\[\]\\\|\-\^\$\?\*\+\{\}\(\)nrt]|\\[pPu]\{[^\}]*\}'"/>
    <!-- this is a regular expression pattern to find characters that designate groups in a regular expression -->
    <xsl:variable name="grouping-characters-in-regex" select="'[\(\)\{\}\[\]]'"/>
    
    <xsl:function name="tan:escape" as="xs:string*">
        <!-- Input: any sequence of strings -->
        <!-- Output: each string prepared for regular expression searches, i.e., with reserved characters escaped out. -->
        <xsl:param name="strings" as="xs:string*"/>
        <xsl:copy-of
            select="
                for $i in $strings
                return
                    replace($i, concat('(', $characters-to-escape-when-converting-string-to-regex, ')'), '\\$1')"
        />
    </xsl:function>

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

    <xsl:function name="tan:get-ucd-decomp">
        <xsl:copy-of select="doc('ucd/string-base-translate.xml')"/>
    </xsl:function>
    <xsl:function name="tan:string-base" as="xs:string?">
        <!-- This function takes any string and replaces every character with its base Unicode character.
      E.g., ἀνθρὠπους - > ανθρωπουσ
      This is useful for preparing text to be searched without respect to accents
      -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:variable name="ucd-decomp" select="tan:get-ucd-decomp()"/>
        <xsl:value-of
            select="translate($arg, $ucd-decomp/tan:translate/tan:mapString, $ucd-decomp/tan:translate/tan:transString)"
        />
    </xsl:function>
    <xsl:function name="tan:string-composite" as="xs:string*">
        <!-- Input: a string -->
        <!-- Output: one string per character in the input, with characters that use the input character as a base -->
        <!-- This function is the inverse of tan:string-base, in that it replaces every character with
         those Unicode characters that use it as a base. If none exist, then the character itself is 
         returned.
         E.g., 'Max' - > 'MᴹḾṀṂℳⅯⓂ㎆㎒㎫㎹㎿㏁Ｍ𝐌𝑀𝑴𝓜𝔐𝕄𝕸𝖬𝗠𝘔𝙈𝙼🄼🅋🅪🅫aªàáâãäåāăąǎǟǡǻȁȃȧᵃḁẚạảấầẩẫậắằẳẵặₐ℀℁ⓐ㏂ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊xˣẋẍₓⅹⅺⅻⓧｘ𝐱𝑥𝒙𝓍𝔁𝔵𝕩𝖝𝗑𝘅𝘹𝙭𝚡'
         This is useful for preparing regex character classes to broaden a search. 
      -->
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:variable name="ucd-decomp" select="tan:get-ucd-decomp()"/>
            <xsl:analyze-string select="$arg" regex=".">
                <xsl:matching-substring>
                    <xsl:variable name="char" select="."/>
                    <xsl:variable name="reverse-translate-match"
                        select="$ucd-decomp/tan:translate/tan:reverse/tan:transString[text() = $char]"/>
                    <xsl:value-of
                        select="
                            if (exists($reverse-translate-match)) then
                                concat($char, string-join($reverse-translate-match/tan:mapString, ''))
                            else
                                $char"
                    />
                </xsl:matching-substring>
            </xsl:analyze-string>
    </xsl:function>

    <xsl:function name="tan:codepoints-to-string" as="xs:string?">
        <!-- Input: any number of integers -->
        <!-- Output: the string value representation, but only if the integers represent valid characters in XML -->
        <!-- Like fn:codepoints-to-string(), but filters out illegal XML characters -->
        <xsl:param name="arg" as="xs:integer*"/>
        <xsl:copy-of
            select="codepoints-to-string($arg[. = (9, 10, 13) or (. ge 32 and . le 65533)])"/>
    </xsl:function>

    <xsl:function name="tan:process-regex-escape-u" as="xs:string?">
        <!-- Input: a string that is inside the braces of a \u{} expression -->
        <!-- Output: the expansion of the expression -->
        <!-- Acceptable values of \u{}: -->
        <!-- 'angle \u{4d-4f, 51}' - - > 'angle [MNOQ]' -->
        <!-- 1. Individual hex values or ranges of them, separated by a comma or space. Values will be replaced with the corresponding Unicode characters -->
        <!-- 2. Characters terminated by the question mark. Characters will be replaced by any Unicode character that has as a base the characters preceding the final question mark -->
        <!-- E.g., \u{λ\u{ο?}γ\u{ο?}} - - > 'λ[οόὀὁὂὃὄὅὸό𝛐𝜊𝝄𝝾𝞸]γ[οόὀὁὂὃὄὅὸό𝛐𝜊𝝄𝝾𝞸]' -->
        <!-- 3. Words chained by preceding periods or exclamation marks. The expression will by replaced by Unicode characters that have every .-prefaced word in their name, and no !-prefaced words in their name -->
        <!-- E.g., '\u{.greek.capital.perispomeni}' - - > '[ἎἏἮἯἾἿὟὮὯᾎᾏᾞᾟᾮᾯ]'
        \u{.latin.cedilla} - - > '[ÇçĢģĶķĻļŅņŖŗŞşŢţȨȩᷗḈḉḐḑḜḝḨḩ]'
        \u{.m!small} - - > '[MƜൔᒻᒼᒾᒿᛗᛘᛙᣘᧄᮿᰮᴹḾṀṂℳⓂⱮㄇ㎛㎡㎥㎧㎨㏁㏞㏟ꚳꟽꟿꩌＭ]'  -->
        
        <xsl:param name="val-inside-braces" as="xs:string"/>
        <!-- characters used in the official character names -->
        <xsl:variable name="ucd-name-class" select="'[-#\(\)a-zA-Z0-9]'"/>
        <!-- characters allowed to separate items in a {} escape class, so far restricted to . and ! -->
        <xsl:variable name="sep-class" select="'[\.!]'"/>
        <!-- first normalize spacing around the hyphen and comma, then tokenize on commas and spaces -->
        <xsl:variable name="val-normalized"
            select="replace(normalize-space($val-inside-braces), ' ?([-,]) ?', '$1')"/>
        <xsl:variable name="val-parts" as="xs:string*" select="tokenize($val-normalized, ',| ')"/>
        <xsl:variable name="val-parts-analyzed" as="xs:string*">
            <xsl:for-each select="$val-parts">
                <xsl:choose>
                    <xsl:when test="matches(., '^[0-9a-fA-F]{1,6}(-[0-9a-fA-F]{1,6})?$')">
                        <!-- it's a Unicode codepoint -->
                        <xsl:variable name="range" select="tokenize(., '\s*-\s*')"/>
                        <xsl:variable name="start" select="$range[1]"/>
                        <xsl:variable name="end" select="$range[2]"/>
                        <xsl:variable name="pass-1" as="xs:integer*">
                            <xsl:choose>
                                <xsl:when test="exists($end)">
                                    <xsl:copy-of
                                        select="
                                            for $i in (tan:hex-to-dec($start) to tan:hex-to-dec($end))
                                            return
                                                $i"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="tan:hex-to-dec($start)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:value-of select="tan:codepoints-to-string($pass-1)"/>
                    </xsl:when>
                    <xsl:when test="matches(., '^.+\?$')">
                        <xsl:variable name="text-to-expand" select="replace(., '\?$', '')"/>
                        <xsl:value-of
                            select="string-join(tan:string-composite($text-to-expand), '')"/>
                    </xsl:when>
                    <xsl:when test="matches(., concat('^(', $sep-class, $ucd-name-class, '+)+$'))">
                        <xsl:variable name="ucd-name-analyzed" as="element()">
                            <analysis>
                                <xsl:analyze-string select="."
                                    regex="{concat('(',$sep-class,')(',$ucd-name-class,'+)')}">
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
                            select="tan:get-chars-by-name($ucd-name-analyzed/tan:include, $ucd-name-analyzed/tan:exclude)"
                        />
                        <xsl:value-of
                            select="
                                tan:codepoints-to-string(for $i in $chars-found
                                return
                                    xs:integer($i/@d))"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message
                            select="concat('Malformed {} expression ', ., '. Expression in braces should be hex values or unicode name keywords prepended by . or !')"
                            terminate="yes"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($val-parts-analyzed, '')"/>
    </xsl:function>
    
    <xsl:function name="tan:get-chars-by-name" as="element()*">
        <!-- Input: two sets of strings -->
        <!-- Output: <char> elements from the Unicode database, the words of whose name (or alias) match all the first set and none of the second -->
        <xsl:param name="words-in-name" as="xs:string*"/>
        <xsl:param name="words-not-in-name" as="xs:string*"/>
        <xsl:copy-of
            select="
                $unicode-db/tan:ucd/tan:char[*[every $i in $words-in-name
                    satisfies * = $i and not(some $j in $words-not-in-name
                        satisfies * = $j)]]"
        />
    </xsl:function>
    
    <xsl:function name="tan:replace-by-char-name" as="xs:string*">
        <!-- Input: a string to be changed; three sets of strings; a boolean -->
        <!-- Output: a set of strings following the rules below -->
        <!-- The first input is broken into individual characters. Each character's Unicode name words are returned. Any names found in the first set of strings are removed. tan:get-chars-by-name() is invoked to find replacement characters -->
        <!-- If the boolean is false, then the search will return unicode codepoints that might have other words in their name; otherwise the match must correspond to all words in the target name -->
        <!-- If the analysis of a character results in no hits from tan:get-chars-by-name() then the original character is returned -->
        <!-- The process will be applied to only the first name found, not aliases -->
        <!-- This function was written primarily to transform Greek letters, e.g., acutes into graves -->
        <xsl:param name="string-to-replace" as="xs:string?"/>
        <xsl:param name="words-in-name-to-drop" as="xs:string*"/>
        <xsl:param name="words-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="words-not-in-replacement-char-name" as="xs:string*"/>
        <xsl:param name="search-is-strict" as="xs:boolean?"/>
        <xsl:for-each select="string-to-codepoints($string-to-replace)">
            <xsl:variable name="this-code" select="."/>
            <xsl:variable name="unicode-db-entry" select="$unicode-db/tan:ucd/tan:char[@d = $this-code]"/>
            <xsl:variable name="this-name-words" select="$unicode-db-entry/*[1]/tan:n[not(. = $words-in-name-to-drop)]"/>
            <xsl:variable name="replacements"
                select="tan:get-chars-by-name(($this-name-words, $words-in-replacement-char-name), $words-not-in-replacement-char-name)"
            />
            <xsl:variable name="replacements-culled"
                select="
                    if ($search-is-strict = true()) then
                        $replacements[*[every $i in tan:n
                            satisfies $i = ($this-name-words, $words-in-replacement-char-name)]]
                    else
                        $replacements"
            />
            <xsl:choose>
                <xsl:when test="not(exists($replacements-culled))">
                    <xsl:value-of select="codepoints-to-string(.)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="
                            tan:codepoints-to-string(for $i in $replacements-culled
                            return
                                xs:integer($i/@d))"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>

    <xsl:template match="node()" mode="add-square-brackets">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
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

    <xsl:function name="tan:regex" as="xs:string?">
        <!-- Input: string representing a regex pattern -->
        <!-- Output: the regular expression adjusted to special rules -->
        <xsl:param name="regex" as="xs:string?"/>
        <xsl:variable name="pass-1" as="element()*">
            <xsl:analyze-string select="$regex" regex="{$escapes-in-regex}">
                <xsl:matching-substring>
                    <escape class="{substring(.,2,1)}">
                        <xsl:value-of select="."/>
                    </escape>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:analyze-string select="." regex="{$grouping-characters-in-regex}">
                        <xsl:matching-substring>
                            <group class="{.}">
                                <xsl:value-of select="."/>
                            </group>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <regular>
                                <xsl:value-of select="."/>
                            </regular>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="pass-2" as="element()">
            <results>
                <xsl:copy-of select="tan:regex-loop($pass-1, 0, ())"/>
            </results>
        </xsl:variable>
        <xsl:variable name="pass-3" as="element()*">
            <xsl:apply-templates select="$pass-2" mode="flat-levels-to-hierarchy">
                <xsl:with-param name="next-level-to-group" select="1"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="pass-4" as="xs:string*">
            <xsl:apply-templates select="$pass-3" mode="escape-u"/>
        </xsl:variable>
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for tan:regex()'"/>
            <xsl:message select="'pass 1: ', $pass-1"/>
            <xsl:message select="'pass 2: ', $pass-2"/>
            <xsl:message select="'pass 3: ', $pass-3"/>
            <xsl:message select="'pass 4: ', $pass-4"/>
        </xsl:if>
        <xsl:value-of select="string-join($pass-4, '')"/>
    </xsl:function>

    <xsl:function name="tan:regex-loop" as="element()*">
        <xsl:param name="elements-to-process" as="element()*"/>
        <xsl:param name="current-group-level" as="xs:integer"/>
        <xsl:param name="group-punctuation-so-far" as="xs:string*"/>
        <xsl:choose>
            <xsl:when test="count($elements-to-process) lt 1"/>
            <xsl:otherwise>
                <xsl:variable name="first-element" select="$elements-to-process[1]"/>
                <xsl:variable name="current-group-punctuation"
                    select="$group-punctuation-so-far[last()]"/>
                <xsl:choose>
                    <xsl:when test="name($first-element) = ('regular', 'escape')">
                        <!--<xsl:copy-of select="$next-element"/>-->
                        <xsl:choose>
                            <xsl:when test="$current-group-level gt 0">
                                <xsl:apply-templates select="$first-element"
                                    mode="imprint-level-attribute">
                                    <xsl:with-param name="level" select="$current-group-level"/>
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="$first-element"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:copy-of
                            select="tan:regex-loop($elements-to-process[position() gt 1], $current-group-level, $group-punctuation-so-far)"
                        />
                    </xsl:when>
                    <!-- From here we assume it's a group -->
                    <xsl:when test="$first-element/@class = ('(', '[', '{')">
                        <xsl:apply-templates select="$first-element" mode="imprint-level-attribute">
                            <xsl:with-param name="level" select="$current-group-level + 1"/>
                        </xsl:apply-templates>
                        <xsl:copy-of
                            select="tan:regex-loop($elements-to-process[position() gt 1], $current-group-level + 1, ($group-punctuation-so-far, $first-element/@class))"
                        />
                    </xsl:when>
                    <xsl:when
                        test="
                            ($first-element/@class = ')' and $current-group-punctuation = '(')
                            or ($first-element/@class = ']' and $current-group-punctuation = '[')
                            or ($first-element/@class = '}' and $current-group-punctuation = '{')">
                        <xsl:apply-templates select="$first-element" mode="imprint-level-attribute">
                            <xsl:with-param name="level" select="$current-group-level"/>
                        </xsl:apply-templates>
                        <xsl:copy-of
                            select="tan:regex-loop($elements-to-process[position() gt 1], $current-group-level - 1, $group-punctuation-so-far[position() lt last()])"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message
                            select="concat('Grouping symbol ', $current-group-punctuation, ' cannot be paired with ', $first-element/@class)"
                            terminate="yes"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="*" mode="imprint-level-attribute">
        <xsl:param name="level" as="xs:integer"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="level" select="$level"/>
            <xsl:copy-of select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*" mode="flat-levels-to-hierarchy">
        <xsl:param name="next-level-to-group" as="xs:integer"/>
        <xsl:copy>
            <xsl:copy-of select="@* except @level"/>
            <xsl:for-each-group select="*"
                group-adjacent="
                    if (exists(@level)) then
                        (xs:integer(@level) ge $next-level-to-group)
                    else
                        false()">
                <xsl:choose>
                    <xsl:when test="current-group()[1]/@level = $next-level-to-group">
                        <xsl:variable name="this-group-regrouped" as="element()">
                            <xsl:apply-templates select="current-group()[1]"
                                mode="append-new-content">
                                <xsl:with-param name="new-content"
                                    select="current-group()[position() gt 1]"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:apply-templates select="$this-group-regrouped" mode="#current">
                            <xsl:with-param name="next-level-to-group"
                                select="$next-level-to-group + 1"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="current-group()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*" mode="append-new-content">
        <xsl:param name="new-content"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <xsl:copy-of select="$new-content"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="text()" mode="append-new-content">
        <text>
            <xsl:value-of select="."/>
        </text>
    </xsl:template>

    <xsl:template match="*" mode="escape-u">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="*[@class = 'u']" mode="escape-u">
        <xsl:variable name="val-inside-braces" select="replace(., '.+\{([^\}]*)\}', '$1')"/>
        <xsl:variable name="u-analysis" select="tan:escape(tan:process-regex-escape-u($val-inside-braces))"/>
        <xsl:choose>
            <xsl:when test="ancestor::tan:group/@class = '['">
                <xsl:value-of select="$u-analysis"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('[', $u-analysis, ']')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>



    <xsl:variable name="hex-key" as="xs:string+"
        select="('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')"/>
    <xsl:variable name="base64-key" as="xs:string+"
        select="('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '\')"
    />
    
    <xsl:function name="tan:dec-to-hex" as="xs:string?">
        <!-- Input: xs:integer -->
        <!-- Output: the hexadecimal equivalent as a string, e.g., 31 - > '1F' -->
        <xsl:param name="in" as="xs:integer?"/>
        <xsl:sequence select="tan:dec-to-n($in, 16)"/>
    </xsl:function>
    
    <xsl:function name="tan:dec-to-n" as="xs:string?">
        <!-- Input: two integers, the second less than 17 -->
        <!-- Output: a string that represents the first numeral in base N, where N is the second numeral -->
        <xsl:param name="in" as="xs:integer?"/>
        <xsl:param name="base" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$base le 16">
                <xsl:sequence
                    select="
                        if ($in eq 0)
                        then
                            '0'
                        else
                            concat(if ($in ge $base)
                            then
                                tan:dec-to-n($in idiv $base, $base)
                            else
                                '',
                            $hex-key[($in mod $base) + 1])"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message
                    select="'tan:dec-to-n() does not support base N systems where N is greater than 16 (hexadecimal)'"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="tan:hex-to-dec" as="xs:integer?">
        <!-- Input: a string representing a hexadecimal number -->
        <!-- Output: the integer value, e.g., '1F' - > 31 -->
        <xsl:param name="hex" as="xs:string?"/>
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
    
    <xsl:function name="tan:n-to-dec" as="xs:integer?">
        <!-- Input: string representation of some number; an integer -->
        <!-- Output: an integer representing the first parameter in the base system of the 2nd parameter -->
        <xsl:param name="input" as="xs:string?"/>
        <xsl:param name="base-n" as="xs:integer"/>
        <xsl:variable name="this-key" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$base-n le 16">
                    <xsl:sequence select="$hex-key"/>
                </xsl:when>
                <xsl:when test="$base-n = 64">
                    <xsl:sequence select="$base64-key"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="input-normalized"
            select="
                if ($base-n le 16) then
                    upper-case($input)
                else
                    $input"
        />
        <xsl:variable name="digit-sequence" as="xs:integer*">
            <xsl:analyze-string select="$input-normalized" regex=".">
                <xsl:matching-substring>
                    <xsl:copy-of select="index-of($this-key, .) - 1"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="split-rev" select="reverse($digit-sequence)"/>
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for tan:n-to-dec()'"/>
            <xsl:message select="'input normalized: ', $input-normalized"/>
            <xsl:message select="'input is what base: ', $base-n"/>
            <xsl:message select="'this key: ', $this-key"/>
            <xsl:message select="'digit sequence: ', $digit-sequence"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="exists($this-key)">
                <xsl:copy-of
                    select="
                        sum(for $i in (1 to count($digit-sequence))
                        return
                            $split-rev[$i]
                            * (xs:integer(math:pow($base-n, $i - 1))))"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message
                    select="'tan:n-to-dec() supports systems whose base values are hexadecimal or less, or base64'"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
