<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:rgx="tag:textalign.net,2015:ns"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ucd="http://www.unicode.org/ns/2003/ucd/1.0" exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="../regex-ext-tan-functions.xsl"/>
    <!-- Catalyzing input: any XML file (including this one) -->
    <!-- Main input: the Unicode database in XML format -->
    <!-- Primary output: none --> 
    <!-- Secondary output: an XML file optimized for searching for individual words in Unicode character names, 
        saved at ucd-names-00.0.xml, where 00.0 is the version number -->

    <xsl:variable name="ucd-data" select="document('file:/e:/unicode/ucd.nounihan.grouped.13.0.xml')"/>
    <xsl:variable name="this-version" as="xs:string">
        <xsl:analyze-string select="$ucd-data/*/ucd:description" regex="Unicode (\d+\.\d+)">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:variable>
    
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
        <char cp="{@cp}" val="{rgx:codepoints-to-string(tan:hex-to-dec(@cp))}">
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
    
    <xsl:template match="/">
        <xsl:message select="concat('Saving file to ucd-names.', $this-version, '.xml')"
        />
        <xsl:result-document href="ucd-names.{$this-version}.xml">
            <xsl:apply-templates select="$ucd-data" mode="ucd-data"/>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>