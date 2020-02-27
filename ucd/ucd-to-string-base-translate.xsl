<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:u="http://www.unicode.org/ns/2003/ucd/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <!-- Input: any XML file (including this one) -->
    <!-- Output: an XML file that maps precomposed characters to their base characters. -->
    <xsl:include href="../regex-ext-tan-functions.xsl"/>

    <xsl:variable name="unicode-database" select="document('ucd.nounihan.grouped.xml')"/>
    <xsl:template match="/*">
        <translate>
            <xsl:comment>
                <xsl:copy-of select="$base-chars"/>
            </xsl:comment>
            <mapString><xsl:value-of select="string-join($base-chars/tan:char/@val,'')"/></mapString>
            <transString><xsl:value-of select="string-join($base-chars/tan:char/@base-val,'')"/></transString>
            <reverse>
                <xsl:for-each-group select="$base-chars/tan:char" group-by="@base-val">
                    <transString>
                        <xsl:value-of select="current-grouping-key()"/>
                        <xsl:for-each select="current-group()">
                            <mapString>
                                <xsl:value-of select="@val"/>
                            </mapString>
                        </xsl:for-each>
                    </transString>
                </xsl:for-each-group>
            </reverse>
        </translate>
    </xsl:template>
    
    <xsl:variable name="base-chars" as="element()">
        <base-chars>
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
                    <char cp="{$this-codepoint-dec}"
                        val="{codepoints-to-string($this-codepoint-dec)}"
                        base="{$target-codepoint-dec}"
                        base-val="{codepoints-to-string($target-codepoint-dec)}"/>
                </xsl:if>                
            </xsl:for-each>
            <xsl:for-each select="($unicode-database/u:ucd/u:repertoire/u:group/u:char[@dm and not(starts-with(@dm,'0020 '))])">
                <xsl:variable name="this-codepoint-dec" select="tan:hex-to-dec(@cp)"/>
                <xsl:variable name="target-codepoint-dec" select="tan:hex-to-dec(tan:base-find(@dm))"/>
                <xsl:if test="$target-codepoint-dec != 0">
                    <char cp="{$this-codepoint-dec}"
                        val="{codepoints-to-string($this-codepoint-dec)}"
                        base="{$target-codepoint-dec}"
                        base-val="{codepoints-to-string($target-codepoint-dec)}"/>
                </xsl:if>
            </xsl:for-each>
        </base-chars>
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
