<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:u="http://www.unicode.org/ns/2003/ucd/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <!-- Input: the XML form  of the Unicode database -->
    <!-- Output: an XML file that optimizes the process of going to and from a base character and complex characters that depend upon them. -->
    <xsl:output method="xml"/>
    <xsl:include href="../../incl/TAN-core-functions.xsl"/>

    <xsl:variable name="unicode-database" select="."/>
    <xsl:template match="/*">
        <tan:translate>
            <xsl:comment>
                <xsl:copy-of select="$base-chars"/>
            </xsl:comment>
            <tan:mapString><xsl:value-of select="string-join($base-chars/tan:char/@val,'')"/></tan:mapString>
            <tan:transString><xsl:value-of select="string-join($base-chars/tan:char/@base-val,'')"/></tan:transString>
            <tan:reverse>
                <xsl:for-each-group select="$base-chars/tan:char" group-by="@base-val">
                    <tan:transString>
                        <xsl:value-of select="current-grouping-key()"/>
                        <xsl:for-each select="current-group()">
                            <tan:mapString>
                                <xsl:value-of select="@val"/>
                            </tan:mapString>
                        </xsl:for-each>
                    </tan:transString>
                </xsl:for-each-group>
            </tan:reverse>
        </tan:translate>
    </xsl:template>
    
    <xsl:variable name="base-chars" as="element()">
        <tan:base-chars>
            <xsl:for-each select="$unicode-database/u:ucd/u:repertoire/u:group/u:char[not(@dm)][matches(@NFKC_CF,'^[\dA-F]+$')]">
                <xsl:variable name="this-nfkc-cf-cp" select="@NFKC_CF"/>
                <xsl:variable name="is-lc"
                    select="
                        if (@Lower = 'Y') then
                            true()
                        else
                            false()"
                />
                <xsl:variable name="target-nfkc-cf" select="$unicode-database/u:ucd/u:repertoire/u:group/u:char[@cp = $this-nfkc-cf-cp]"/>
                <xsl:variable name="target-nfkc-cf-is-lc"
                    select="
                        if ($target-nfkc-cf/@Lower = 'Y') then
                            true()
                        else
                            false()"
                />
                <xsl:variable name="this-codepoint-dec" select="tan:hex-to-dec(@cp)"/>
                <xsl:variable name="target-codepoint-dec" select="tan:hex-to-dec($this-nfkc-cf-cp)"/>
                <xsl:if test="$is-lc = $target-nfkc-cf-is-lc">
                    <tan:char cp="{$this-codepoint-dec}"
                        val="{codepoints-to-string($this-codepoint-dec)}"
                        base="{$target-codepoint-dec}"
                        base-val="{codepoints-to-string($target-codepoint-dec)}"/>
                </xsl:if>                
            </xsl:for-each>
            <xsl:for-each select="($unicode-database/u:ucd/u:repertoire/u:group/u:char[@dm and not(starts-with(@dm,'0020 '))])">
                <xsl:variable name="this-codepoint-dec" select="tan:hex-to-dec(@cp)"/>
                <xsl:variable name="target-codepoint-dec" select="tan:hex-to-dec(tan:base-find(@dm))"/>
                <xsl:if test="$target-codepoint-dec != 0">
                    <tan:char cp="{$this-codepoint-dec}"
                        val="{codepoints-to-string($this-codepoint-dec)}"
                        base="{$target-codepoint-dec}"
                        base-val="{codepoints-to-string($target-codepoint-dec)}"/>
                </xsl:if>
            </xsl:for-each>
        </tan:base-chars>
    </xsl:variable>

    <xsl:function name="tan:base-find" as="xs:string">
        <xsl:param name="arg" as="xs:string"/>
        <xsl:variable name="first" select="tokenize($arg, ' ')[1]"/>
        <xsl:value-of
            select="
                if (not($unicode-database/u:ucd/u:repertoire/u:group/u:char[@cp = $first]/@dm)) then
                    $first
                else
                    tan:base-find($unicode-database/u:ucd/u:repertoire/u:group/u:char[@cp = $first][1]/@dm)"
        />
    </xsl:function>

</xsl:stylesheet>
