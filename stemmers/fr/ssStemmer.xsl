<?xml version="1.0" encoding="UTF-8"?>
  <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    version="3.0"
    xmlns:ss="http://hcmc.uvic.ca/ns/ssStemmer">
    <xd:doc scope="stylesheet">
      <xd:desc>
        <xd:p><xd:b>Started on:</xd:b> Oct 31, 2020</xd:p>
        <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
        <xd:p>This is an implementation of the French Snowball stemmer
          described at 
          <xd:a href="https://snowballstem.org/algorithms/french/stemmer.html">snowballstem.org</xd:a>. 
          It follows the pattern of the English stemmer in this project.
        </xd:p>
      </xd:desc>
    </xd:doc>
    
    <!--**************************************************************
       *                                                            * 
       *                    Parameters                              *
       *                                                            *
       **************************************************************-->
    
    <!-- None so far. -->
    
    <!--**************************************************************
       *                                                            * 
       *                    Variables                               *
       *                                                            *
       **************************************************************-->
  
    <xd:doc scope="component">
      <xd:desc>The <xd:ref name="vowel">vowel</xd:ref> variable is a character 
        class of vowels [aeiouyâàëéêèïîôûù].</xd:desc>
    </xd:doc>
    <xsl:variable name="vowel" as="xs:string">[aeiouyâàëéêèïîôûù]</xsl:variable>
    
    <xd:doc>
      <xd:desc>The <xd:ref name="nonVowel">nonVowel</xd:ref> variable is 
        a character class of non-vowels.</xd:desc>
    </xd:doc>
    <xsl:variable name="nonVowel">[^aeiouyâàëéêèïîôûù]</xsl:variable>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="RVExceptRex">RVExceptRex</xd:ref> is a regular expression
        which returns returns RV when applied to a token which fits the exception pattern.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="RVExceptRex" as="xs:string" select="'^(par|col|tap)(.*)$'"/>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="RVARex">RVARex</xd:ref> is a regular expression
        which returns returns RV for words beginning with two vowels.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="RVARex" as="xs:string" select="concat('^', $vowel, '{2}', '.(.*)$')"/>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="RVBRex">RVBRex</xd:ref> is a regular expression
        which returns returns RV for words not beginning with two vowels.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="RVBRex" as="xs:string" select="concat('^.', $nonVowel, '*', $vowel, '(.*)$')"/>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="R1R2Rex">R1R2Rex</xd:ref> is a regular expression
        which returns R1, defined as "the region after the first non-vowel 
        following a vowel, or the end of the word if there is no such non-vowel".
        It also returns R2 when applied to R1.
      </xd:desc>
    </xd:doc>
    <xsl:variable name="R1R2Rex" as="xs:string" select="concat('^.*?', $vowel, $nonVowel, '(.*)$')"/>
    
    <!--**************************************************************
       *                                                            * 
       *                         Functions                          *
       *                                                            *
       **************************************************************-->
  
    <xd:doc scope="component">
      <xd:desc><xd:ref name="ss:stem" type="function">ss:stem</xd:ref> is the core function that
        takes a single token and returns its stemmed version. This function should be deterministic
        (same results every time from same input), so we mark it as new-each-time="no".
      </xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:result>The stemmed version of the token.</xd:result>
    </xd:doc>
    <xsl:function name="ss:stem" as="xs:string" new-each-time="no">
      <xsl:param name="token" as="xs:string"/>
      <!-- TODO, of course. -->
      <xsl:sequence select="$token"/>
    </xsl:function>
    
    <xd:doc scope="component">
      <xd:desc><xd:ref name="ss:preflight" type="function">ss:preflight</xd:ref> does a couple of simple
        replacements that need to precede the actual stemming process.
      </xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:result>The treated version of the token.</xd:result>
    </xd:doc>
    <xsl:function name="ss:preflight" as="xs:string">
      <xsl:param name="token" as="xs:string"/>
      <xsl:value-of select="replace(
                            replace(
                            replace(
                            replace(
                            replace(
                            replace(
                            replace($token, 
                                    '(' || $vowel || ')i(' || $vowel || ')', '$1I$2'),
                                    '(' || $vowel || ')u(' || $vowel || ')', '$1U$2'),
                                    '(' || $vowel || ')y', '$1Y'),
                                    'y(' || $vowel || ')', 'Y$1'),
                                    'qu', 'qU'),
                                    'ë', 'He'),
                                    'ï', 'Hi')
        "/>
    </xsl:function>
  
    <xd:doc scope="component">
      <xd:desc><xd:ref name="ss:getRVR1R2" type="function">ss:getRVR1R2</xd:ref>
        decomposes an input token to get the RV, R1 and R2 regions, 
        and returns the string values of those three 
        regions, along with their offsets.</xd:desc>
      <xd:param name="token">Input token string</xd:param>
      <xd:result>A sequence consisting of three strings for RV, R1 and
        R2, and three integers for the offsets of RV, R1 and R2 respectively.</xd:result>
    </xd:doc>
    <xsl:function name="ss:getRVR1R2" as="item()+">
      <xsl:param name="token" as="xs:string"/>
      <xsl:variable name="RV" as="xs:string" select="if (matches($token, $RVExceptRex)) then 
                                                         replace($token, $RVExceptRex, '$2') else
                                                     if (matches($token, $RVARex)) then
                                                         replace($token, $RVARex, '$1') else
                                                     if (matches($token, $RVBRex)) then
                                                         replace($token, $RVBRex, '$1') else
                                                         ''"/>
      <xsl:variable name="RVIndex" as="xs:integer" select="(string-length($token) - string-length($RV)) + 1"/>
      <xsl:variable name="R1" as="xs:string" select="if (matches($token, $R1R2Rex)) then
                                                         replace($token, $R1R2Rex, '$1') else
                                                         ''"/>
      <xsl:variable name="R1Index" as="xs:integer" select="(string-length($token) - string-length($R1)) + 1"/>
      <xsl:variable name="R2Candidate" as="xs:string" select="replace($R1, $R1R2Rex, '$1')"/>
      <xsl:variable name="R2" select="if ($R2Candidate = $R1) then '' else $R2Candidate"/>
      <xsl:variable name="R2Index" as="xs:integer" select="if ($R2Candidate = $R1) then string-length($token) + 1 else (string-length($token) - string-length($R2)) + 1"/>
      <xsl:sequence select="($RV, $R1, $R2, $RVIndex, $R1Index, $R2Index)"/>
    </xsl:function>
  
</xsl:stylesheet>