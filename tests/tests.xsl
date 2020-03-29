<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:rgx="tag:textalign.net,2015:ns" version="3.0">
    <!-- CATALYZING INPUT: any XML document, including this one -->
    <!-- MAIN INPUT: the global variables in this stylesheet -->
    <!-- MAIN OUTPUT: an analysis of the global variables, passed through the special regular expressions -->
    <xsl:import href="../regex-ext-tan-functions.xsl"/>
    <xsl:output indent="yes"/>
    
    <!--<xsl:param name="default-version" select="5.1"/>-->

    <xsl:param name="truncate-text-at-length" as="xs:integer?" select="1000"/>

    <!--<xsl:template match="comment()" mode="#all">
        <xsl:copy-of select="."/>
    </xsl:template>-->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:variable name="sample-escape-us" as="element()">
        <samples>
            <xsl:text>&#xa;      </xsl:text>
            <xsl:comment>Latin letters with carons</xsl:comment>
            <u>.latin.caron</u>
            <xsl:comment> The letter A, as long as it is not called a Latin letter </xsl:comment>
            <u>.a!latin</u>
            <xsl:comment> All brackets </xsl:comment>
            <u>.bracket</u>
            <xsl:comment> All Roman numerals </xsl:comment>
            <u>.roman.numeral</u>
            <xsl:comment> all variations of a and A </xsl:comment>
            <u>+a</u>
            <xsl:comment> the output of the above, in reverse</xsl:comment>
            <u>-aªàáâãäåāăąǎǟǡǻȁȃȧᵃḁẚạảấầẩẫậắằẳẵặₐ℀℁ⓐ㏂ａ𝐚𝑎𝒂𝒶𝓪𝔞𝕒𝖆𝖺𝗮𝘢𝙖𝚊</u>
            <xsl:comment> variations on the plus and period </xsl:comment>
            <u>++.</u>
            <xsl:comment>Characters with BOTTLE in their name</xsl:comment>
            <u>.bottle</u>
            <xsl:comment>Suspension marks</xsl:comment>
            <u>.suspension.mark</u>
        </samples>
    </xsl:variable>

    <xsl:template match="*[text()[matches(., '\S')]]" mode="process-regex-escape-u">
        <xsl:variable name="output" select="rgx:process-regex-escape-u(.)"/>
        <process-regex-escape-u>
            <xsl:copy-of select="."/>
            <output length="{string-length($output)}">
                <xsl:sequence select="$output"/>
            </output>
        </process-regex-escape-u>
    </xsl:template>

    <xsl:variable name="chars-with-combining-in-name"
        select="rgx:process-regex-escape-u('.combining')"/>
    <xsl:variable name="chars-without-combining-in-name"
        select="rgx:process-regex-escape-u('!combining')"/>
    <xsl:variable name="chars-with-combining-in-name-that-do-not-have-mark-property"
        select="replace($chars-with-combining-in-name, '[\p{M}\p{Mn}\p{Mc}\p{Me}]', '')"/>
    <xsl:variable name="chars-with-combining-in-name-that-do-not-have-mark-property-and-are-not-assigned"
        select="replace($chars-with-combining-in-name-that-do-not-have-mark-property, '[\p{Cn}]', '')"/>
    <xsl:variable name="chars-without-combining-in-name-that-do-have-mark-property"
        select="replace($chars-with-combining-in-name, '[\P{M}\P{Mn}\P{Mc}\P{Me}]', '')"/>

    <xsl:variable name="chars-with-symbol-in-name" select="rgx:process-regex-escape-u('.symbol')"/>
    <xsl:variable name="chars-with-symbol-in-name-that-do-not-have-symbol-property"
        select="replace($chars-with-symbol-in-name, '[\p{S}\p{Sm}\p{Sc}\p{Sk}\p{So}]', '')"/>
    
    <xsl:variable name="chars-with-digit-or-numeral-in-name" select="rgx:process-regex-escape-u('.digit .numeral')"/>
    <xsl:variable name="chars-with-digit-or-numeral-in-name-that-do-not-have-number-property"
        select="replace($chars-with-digit-or-numeral-in-name, '[\p{N}]', '')"/>
    <xsl:variable name="chars-with-digit-or-numeral-in-name-that-do-not-have-number-property-and-are-not-assigned"
        select="replace($chars-with-digit-or-numeral-in-name-that-do-not-have-number-property, '[\p{Cn}]', '')"/>
    
    <xsl:variable name="chars-with-greek-in-name" select="rgx:process-regex-escape-u('.greek')"/>
    <xsl:variable name="chars-with-greek-in-name-that-are-not-in-greek-blocks"
        select="replace($chars-with-greek-in-name, '[\p{IsGreek}\p{IsGreekExtended}\p{IsAncientGreekNumbers}\p{IsAncientGreekMusicalNotation}\p{IsAncientSymbols}]', '')"/>
    
    <xsl:variable name="chars-with-b-in-name" select="rgx:process-regex-escape-u('.b')"/>
    <xsl:variable name="chars-with-b-and-latin-in-name" select="rgx:process-regex-escape-u('.b.latin')"/>
    <xsl:variable name="chars-with-b-as-base-character" select="string-join(rgx:string-to-composites('bB'))"/>
    
    <xsl:variable name="chars-with-with-in-name" select="rgx:process-regex-escape-u('.with')"/>
    <xsl:variable name="chars-with-with-in-name-that-do-not-decompose" as="xs:string*">
        <xsl:analyze-string select="$chars-with-with-in-name" regex=".">
            <xsl:matching-substring>
                <xsl:variable name="this-char" select="."/>
                <xsl:variable name="this-decomp-db-entry" select="$default-ucd-decomp-db/*/rgx:char[@val =$this-char]"/>
                <xsl:if test="not(exists($this-decomp-db-entry))">
                    <xsl:value-of select="."/>
                </xsl:if>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:variable>
    <xsl:variable name="chars-with-with-and-and-in-name" select="rgx:process-regex-escape-u('.with.and')"/>
    <xsl:variable name="chars-with-with-and-and-in-name-that-do-not-decompose" as="xs:string*">
        <xsl:analyze-string select="$chars-with-with-and-and-in-name" regex=".">
            <xsl:matching-substring>
                <xsl:variable name="this-char" select="."/>
                <xsl:variable name="this-decomp-db-entry" select="$default-ucd-decomp-db/*/rgx:char[@val =$this-char]"/>
                <xsl:if test="not(exists($this-decomp-db-entry))">
                    <xsl:value-of select="."/>
                </xsl:if>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:variable>
    
    <xsl:variable name="greek-pattern-for-accented-vowels"
        select="rgx:regex('\u{.greek.tonos .greek.oxia .greek.varia .greek.perispomeni}')"/>
    <xsl:variable name="greek-pattern-for-acute-vowels"
        select="rgx:regex('\u{.greek.tonos .greek.oxia}')"/>
    <!-- the first example uses U+03CC GREEK SMALL LETTER OMICRON WITH TONOS, 
        the second example uses U+1F79 GREEK SMALL LETTER OMICRON WITH OXIA -->
    <xsl:variable name="greek-words-with-two-accents" select="'σῶσόν σῶσόν ᾊᾴ'"/>
    <xsl:variable name="second-accent-dropped-from-greek" as="xs:string*">
        <xsl:analyze-string select="$greek-words-with-two-accents"
            regex="({$greek-pattern-for-accented-vowels}\S*)({$greek-pattern-for-acute-vowels})">
            <xsl:matching-substring>
                <xsl:variable name="result-pass-1" select="rgx:replace-by-char-name(regex-group(2), ('oxia', 'tonos', 'with'), (), (), true())"/>
                <xsl:variable name="result-pass-2" select="rgx:replace-by-char-name($result-pass-1, ('oxia', 'tonos', 'and'), (), (), true())"/>
                <xsl:value-of select="regex-group(1)"/>
                <xsl:value-of select="$result-pass-2"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:variable>
    

    <xsl:variable name="raw-output" as="element()">
        <regex-analysis>

            <xsl:apply-templates select="$sample-escape-us" mode="process-regex-escape-u"/>

            <combining-chars>
                <chars-with-combining-in-name>
                    <xsl:sequence select="$chars-with-combining-in-name"/>
                </chars-with-combining-in-name>
                <chars-with-combining-in-name-that-do-not-have-mark-property>
                    <xsl:sequence
                        select="$chars-with-combining-in-name-that-do-not-have-mark-property"/>
                </chars-with-combining-in-name-that-do-not-have-mark-property>
                <chars-with-combining-in-name-that-do-not-have-mark-property-and-are-not-assigned>
                    <xsl:sequence
                        select="$chars-with-combining-in-name-that-do-not-have-mark-property-and-are-not-assigned"
                    />
                </chars-with-combining-in-name-that-do-not-have-mark-property-and-are-not-assigned>
                <chars-without-combining-in-name>
                    <xsl:sequence select="$chars-without-combining-in-name"/>
                </chars-without-combining-in-name>
                <chars-without-combining-in-name-that-do-have-mark-property length="">
                    <xsl:sequence
                        select="$chars-without-combining-in-name-that-do-have-mark-property"/>
                </chars-without-combining-in-name-that-do-have-mark-property>
            </combining-chars>
            <symbol-chars>
                <chars-with-symbol-in-name>
                    <xsl:sequence select="$chars-with-symbol-in-name"/>
                </chars-with-symbol-in-name>
                <chars-with-symbol-in-name-that-do-not-have-symbol-property>
                    <xsl:sequence
                        select="$chars-with-symbol-in-name-that-do-not-have-symbol-property"/>
                </chars-with-symbol-in-name-that-do-not-have-symbol-property>
            </symbol-chars>
            <numerals>
                <chars-with-digit-or-numeral-in-name>
                    <xsl:sequence select="$chars-with-digit-or-numeral-in-name"/>
                </chars-with-digit-or-numeral-in-name>
                <chars-with-digit-or-numeral-in-name-that-do-not-have-number-property>
                    <xsl:sequence
                        select="$chars-with-digit-or-numeral-in-name-that-do-not-have-number-property"
                    />
                </chars-with-digit-or-numeral-in-name-that-do-not-have-number-property>
                <chars-with-digit-or-numeral-in-name-that-do-not-have-number-property-and-are-not-assigned>
                    <xsl:sequence
                        select="$chars-with-digit-or-numeral-in-name-that-do-not-have-number-property-and-are-not-assigned"
                    />
                </chars-with-digit-or-numeral-in-name-that-do-not-have-number-property-and-are-not-assigned>
            </numerals>
            <greek>
                <chars-with-greek-in-name>
                    <xsl:sequence select="$chars-with-greek-in-name"/>
                </chars-with-greek-in-name>
                <chars-with-greek-in-name-that-are-not-in-greek-blocks>
                    <xsl:sequence select="$chars-with-greek-in-name-that-are-not-in-greek-blocks"/>
                </chars-with-greek-in-name-that-are-not-in-greek-blocks>
            </greek>
            <comparison-of-name-and-base-chars>
                <letter-b>
                    <b-by-name>
                        <xsl:sequence select="$chars-with-b-in-name"/>
                    </b-by-name>
                    <b-and-latin-by-name>
                        <xsl:sequence select="$chars-with-b-and-latin-in-name"/>
                    </b-and-latin-by-name>
                    <bB-composites>
                        <xsl:sequence select="$chars-with-b-as-base-character"/>
                    </bB-composites>
                    <unique-to-b-latin-name>
                        <xsl:sequence select="rgx:replace($chars-with-b-and-latin-in-name, '[' || $chars-with-b-as-base-character || ']', '')"/>
                    </unique-to-b-latin-name>
                    <unique-to-bB-composites>
                        <xsl:sequence select="rgx:replace($chars-with-b-as-base-character, '[' || $chars-with-b-and-latin-in-name || ']', '')"/>
                    </unique-to-bB-composites>
                </letter-b>
            </comparison-of-name-and-base-chars>
            <comparison-of-characters-with-with-in-name>
                <all-of-them><xsl:value-of select="$chars-with-with-in-name"/></all-of-them>
                <those-that-dont-decompose><xsl:value-of select="string-join($chars-with-with-in-name-that-do-not-decompose)"/></those-that-dont-decompose>
                <those-with-and><xsl:value-of select="$chars-with-with-and-and-in-name"/></those-with-and>
                <those-that-dont-decompose><xsl:value-of select="string-join($chars-with-with-and-and-in-name-that-do-not-decompose)"/></those-that-dont-decompose>
            </comparison-of-characters-with-with-in-name>
            <greek-word-replacement>
                <greek-pattern-for-accented-vowels>
                    <xsl:value-of select="$greek-pattern-for-accented-vowels"/>
                </greek-pattern-for-accented-vowels>
                <greek-pattern-for-acute-vowels>
                    <xsl:value-of select="$greek-pattern-for-acute-vowels"/>
                </greek-pattern-for-acute-vowels>
                <greek-word-with-two-accents>
                    <xsl:value-of select="$greek-words-with-two-accents"/>
                </greek-word-with-two-accents>
                <second-accent-dropped-from-greek>
                    <xsl:value-of select="string-join($second-accent-dropped-from-greek)"/>
                </second-accent-dropped-from-greek>
            </greek-word-replacement>
        </regex-analysis>
    </xsl:variable>

    <xsl:template match="*[not(*)]" mode="calculate-string-length">
        <xsl:variable name="this-length" select="string-length(.)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="length" select="$this-length"/>
            <xsl:choose>
                <xsl:when test="$this-length gt $truncate-text-at-length">
                    <xsl:attribute name="truncated" select="true()"/>
                    <xsl:value-of select="substring(., 1, $truncate-text-at-length)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/">
        
        <xsl:apply-templates select="$raw-output" mode="calculate-string-length"/>
    </xsl:template>
</xsl:stylesheet>
