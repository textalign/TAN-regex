<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ucd="http://www.unicode.org/ns/2003/ucd/1.0" exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="../regex-ext-tan-functions.xsl"/>
    <!-- Input: any xml document -->
    <!-- Output: a version of the Unicode database that is optimized for searching for individual Unicode character names -->
    <xsl:variable name="ucd-data" select="document('ucd.nounihan.grouped.xml')"/>
    <xsl:template match="/">
        <xsl:document>
            <xsl:apply-templates select="$ucd-data" mode="ucd-data"/>
        </xsl:document>
    </xsl:template>
    
    <xsl:template match="* | text()" mode="ucd-data">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="ucd:ucd" mode="ucd-data">
        <ucd>
            <xsl:apply-templates mode="#current"/>
        </ucd>
    </xsl:template>
    <xsl:template match="ucd:char[@cp]" mode="ucd-data">
        <xsl:text>&#xa;</xsl:text>
        <char cp="{@cp}" d="{tan:hex-to-dec(@cp)}">
            <xsl:apply-templates select="@na" mode="#current"/>
            <xsl:apply-templates select="ucd:name-alias" mode="#current"/>
        </char>
    </xsl:template>
    
    <xsl:template match="@na" mode="ucd-data">
        <na>
            <xsl:for-each select="tokenize(lower-case(.),'\s+')">
                <n><xsl:value-of select="."/></n>
            </xsl:for-each>
        </na>
    </xsl:template>
    <xsl:template match="ucd:name-alias" mode="ucd-data">
        <alias>
            <xsl:for-each select="tokenize(lower-case(@alias),'\s+')">
                <n><xsl:value-of select="."/></n>
            </xsl:for-each>
        </alias>
    </xsl:template>
</xsl:stylesheet>