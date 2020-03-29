<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:rgx="tag:textalign.net,2015:ns"
    xmlns:u="http://www.unicode.org/ns/2003/ucd/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="3.0">
    <!-- Catalyzing input: any XML file (including this one) -->
    <!-- Main input: the Unicode database in XML format -->
    <!-- Primary output: none -->
    <!-- Secondary output: an XML file that maps decomposable characters to their parts, saved at 
        ucd-decomp.00.0.xml, where 00.0 is the unicode version number. Another secondary output file 
        will be saved at ucd-decomp-single.00.0.xml, which supports a translate function for one-to-one 
        interchange between composite and singular base. -->

    <xsl:include href="../regex-ext-tan-functions.xsl"/>
    
    <xsl:key name="char-by-cp" match="*:char" use="@cp"/>

    <xsl:variable name="unicode-database" select="document('file:/e:/unicode/ucd.all.grouped.13.0.xml')"/>

    <xsl:variable name="this-version" as="xs:string">
        <xsl:analyze-string select="$unicode-database/*/u:description" regex="Unicode (\d+\.\d+)">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:variable>

    <xsl:function name="rgx:get-ucd-decomp-database" as="document-node()?">
        <!-- Input: a ucd database in XML, a loop counter -->
        <!-- Output: the database mapping composite characters to their bases -->
        <xsl:param name="ucd-database-so-far" as="document-node()"/>
        <xsl:param name="loop-counter" as="xs:integer"/>
        <xsl:variable name="these-chars" select="$ucd-database-so-far//*:char"/>
        <xsl:variable name="these-resolved-chars" select="$these-chars[rgx:b]"/>
        <xsl:variable name="these-unresolved-chars" select="$these-chars except $these-resolved-chars"/>
        <xsl:choose>
            <xsl:when test="$loop-counter gt 10">
                <xsl:message>Function is looping; exiting</xsl:message>
                <xsl:apply-templates select="$ucd-database-so-far" mode="clean-up-decomp-db"/>
            </xsl:when>
            <xsl:when test="not(exists($these-unresolved-chars))">
                <xsl:apply-templates select="$ucd-database-so-far" mode="clean-up-decomp-db"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'Processing UCD database, pass ' || string($loop-counter)"/>
                <xsl:variable name="revised-ucd-database" as="document-node()">
                    <xsl:apply-templates select="$ucd-database-so-far" mode="build-ucd-bs">
                        <xsl:with-param name="resolved-chars" tunnel="yes"
                            select="$these-resolved-chars"/>
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:sequence
                    select="rgx:get-ucd-decomp-database($revised-ucd-database, $loop-counter + 1)"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="/" mode="build-ucd-bs clean-up-decomp-db build-ucd-decomp-simple">
        <xsl:document>
            <xsl:apply-templates mode="#current"/>
        </xsl:document>
    </xsl:template>
    <xsl:template match="* | text()" mode="build-ucd-bs">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="/*" mode="build-ucd-bs">
        <decomp>
            <xsl:apply-templates mode="#current"/>
        </decomp>
    </xsl:template>
    <xsl:template match="rgx:char" mode="build-ucd-bs">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="u:char[not(@dm) or (@dm eq '#')]" priority="1" mode="build-ucd-bs">
        <xsl:variable name="this-val" select="rgx:codepoints-to-string(tan:hex-to-dec(@cp))"/>
        <xsl:if test="string-length($this-val) gt 0">
            <char>
                <xsl:copy-of select="@cp"/>
                <xsl:attribute name="val" select="$this-val"/>
                <b>
                    <!-- we include the general category, because a later user may wish to find components that conform to a 
                        specific type. In not all cases is the first component the main one of interest to a user. -->
                    <xsl:copy-of select="ancestor-or-self::*[@gc][1]/@gc"/>
                    <xsl:value-of select="$this-val"/>
                </b>
            </char>
        </xsl:if>
    </xsl:template>
    <xsl:template match="u:char" mode="build-ucd-bs">
        <xsl:param name="resolved-chars" tunnel="yes" as="element()*"/>
        <xsl:variable name="these-dms" select="tokenize(@dm, ' ')"/>
        <xsl:variable name="these-matching-chars" select="key('char-by-cp', $these-dms, root(.))[rgx:b]"/>
        <xsl:variable name="char-can-be-fully-resolved"
            select="
                every $i in $these-dms
                    satisfies exists($these-matching-chars[@cp = $i])"
        />
        <xsl:choose>
            <xsl:when test="$char-can-be-fully-resolved">
                <xsl:variable name="this-val" select="rgx:codepoints-to-string(tan:hex-to-dec(@cp))"/>
                <char>
                    <xsl:copy-of select="@cp"/>
                    <xsl:attribute name="val" select="$this-val"/>
                    <xsl:for-each select="$these-dms">
                        <xsl:variable name="this-cp" select="."/>
                        <xsl:variable name="this-matching-char"
                            select="$these-matching-chars[@cp = $this-cp]"/>
                        <xsl:if test="count($this-matching-char) gt 1">
                            <xsl:message
                                select="string(count($this-matching-char)) || ' matching characters found for ' || $this-cp"
                            />
                        </xsl:if>
                        <xsl:copy-of select="$this-matching-char/rgx:b"/>
                    </xsl:for-each>
                </char>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="/rgx:decomp" mode="clean-up-decomp-db">
        <xsl:copy>
            <!-- keep only those characters that permit decomposition -->
            <xsl:for-each select="rgx:char[@val != rgx:b]">
                <xsl:text>&#xa;</xsl:text>
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:variable name="ucd-decomp-database" as="document-node()?"
        select="rgx:get-ucd-decomp-database($unicode-database, 1)"/>
    
    <xsl:variable name="ucd-decomp-simple-database" as="document-node()?">
        <xsl:apply-templates select="$ucd-decomp-database" mode="build-ucd-decomp-simple"/>
    </xsl:variable>
    
    <xsl:template match="/*" mode="build-ucd-decomp-simple">
        <!-- For annotations on the rationale for identifying relevant chars, see rgx:string-base() -->
        <xsl:variable name="relevant-chars" as="element()+">
            <xsl:for-each select="rgx:char">
                <xsl:variable name="these-base-chars" select="rgx:b[@gc = $key-gc-vals]"/>
                <xsl:choose>
                    <xsl:when test="count(rgx:b) eq 1">
                        <xsl:copy-of select="."/>
                    </xsl:when>
                    <xsl:when test="count(distinct-values(rgx:b)) eq 1">
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="rgx:b[1]"/>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:when test="count(distinct-values($these-base-chars)) eq 1">
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="$these-base-chars[1]"/>
                        </xsl:copy>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <translate>
            <mapString>
                <xsl:value-of select="string-join($relevant-chars/@val)"/>
            </mapString>
            <transString>
                <xsl:value-of select="string-join($relevant-chars/rgx:b)"/>
            </transString>
        </translate>
    </xsl:template>

    <!-- main template -->

    <xsl:template match="/">
        <xsl:message select="concat('Saving file to ucd-decomp.', $this-version, '.xml')"/>
        <xsl:result-document href="ucd-decomp.{$this-version}.xml">
            <xsl:copy-of copy-namespaces="no" select="$ucd-decomp-database"/>
        </xsl:result-document>
        <xsl:message select="concat('Saving file to ucd-decomp-simple.', $this-version, '.xml')"/>
        <xsl:result-document href="ucd-decomp-simple.{$this-version}.xml">
            <xsl:copy-of copy-namespaces="no" select="$ucd-decomp-simple-database"/>
        </xsl:result-document>
        
    </xsl:template>

</xsl:stylesheet>
