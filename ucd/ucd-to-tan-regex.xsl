<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns = "tag:textalign.net,2015:ns" xmlns:tan = "tag:textalign.net,2015:ns" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ucd="http://www.unicode.org/ns/2003/ucd/1.0"
    exclude-result-prefixes="xs ucd tan"
    version="2.0">
    <!-- This template converts the Unicode database to a version that makes
    it easy to search for parts of the character names -->
    <xsl:template match="/">
        <xsl:document>
            <ucd>
                <xsl:for-each select="//ucd:char[@na1 or @na]">
                    <char cp="{@cp}">
                        <xsl:for-each select="distinct-values(for $i in (@na1, @na, ucd:name-alias/@alias)
                            return tokenize(lower-case($i),'\s+'))">
                            <n><xsl:copy-of select="."/></n>
                        </xsl:for-each>
                    </char>
                </xsl:for-each>
            </ucd>
        </xsl:document>
    </xsl:template>
</xsl:stylesheet>