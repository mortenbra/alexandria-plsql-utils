create or replace package body json_util_pkg
as

  /*

  Purpose:    JSON utilities for PL/SQL

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.01.2010  Created
  
  */


  g_json_null_object             constant varchar2(20) := '{ }';


function get_xml_to_json_stylesheet return varchar2
as
begin

  /*

  Purpose:    return XSLT stylesheet for XML to JSON transformation

  Remarks:    see http://code.google.com/p/xml2json-xslt/

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.01.2010  Created
  MBR     30.01.2010  Added fix for nulls
  
  */


  return '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
  Copyright (c) 2006, Doeke Zanstra
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, 
  are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer. Redistributions in binary 
  form must reproduce the above copyright notice, this list of conditions and the 
  following disclaimer in the documentation and/or other materials provided with 
  the distribution.

  Neither the name of the dzLib nor the names of its contributors may be used to 
  endorse or promote products derived from this software without specific prior 
  written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
  THE POSSIBILITY OF SUCH DAMAGE.
-->

  <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="text/x-json"/>
  <xsl:strip-space elements="*"/>
  <!--contant-->
  <xsl:variable name="d">0123456789</xsl:variable>

  <!-- ignore document text -->
  <xsl:template match="text()[preceding-sibling::node() or following-sibling::node()]"/>

  <!-- string -->
  <xsl:template match="text()">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="."/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- Main template for escaping strings; used by above template and for object-properties 
       Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
  <xsl:template name="escape-string">
    <xsl:param name="s"/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape-bs-string">
      <xsl:with-param name="s" select="$s"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>
  
  <!-- Escape the backslash (\) before everything else. -->
  <xsl:template name="escape-bs-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''\'')">
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''\''),''\\'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-bs-string">
          <xsl:with-param name="s" select="substring-after($s,''\'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Escape the double quote ("). -->
  <xsl:template name="escape-quot-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''&quot;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&quot;''),''\&quot;'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="substring-after($s,''&quot;'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Can''t escape backslash
       or double quote here, because they don''t replace characters (&#x0; becomes \t), but they prefix 
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be 
       processed first. This function can''t do that. -->
  <xsl:template name="encode-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <!-- tab -->
      <xsl:when test="contains($s,''&#x9;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#x9;''),''\t'',substring-after($s,''&#x9;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- line feed -->
      <xsl:when test="contains($s,''&#xA;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xA;''),''\n'',substring-after($s,''&#xA;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- carriage return -->
      <xsl:when test="contains($s,''&#xD;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xD;''),''\r'',substring-after($s,''&#xD;''))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$s"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- number (no support for javascript mantise) -->
  <xsl:template match="text()[not(string(number())=''NaN'')]">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- boolean, case-insensitive -->
  <xsl:template match="text()[translate(.,''TRUE'',''true'')=''true'']">true</xsl:template>
  <xsl:template match="text()[translate(.,''FALSE'',''false'')=''false'']">false</xsl:template>

  <!-- item:null -->
  <xsl:template match="*[count(child::node())=0]">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="local-name()"/>
    </xsl:call-template>
    <xsl:text>:null</xsl:text>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if> <!-- MBR 30.01.2010: added this line as it appeared to be missing from stylesheet --> 
  </xsl:template>

  <!-- object -->
  <xsl:template match="*" name="base">
    <xsl:if test="not(preceding-sibling::*)">{</xsl:if>
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="name()"/>
    </xsl:call-template>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates select="child::node()"/>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if>
  </xsl:template>

  <!-- array -->
  <xsl:template match="*[count(../*[name(../*)=name(.)])=count(../*) and count(../*)&gt;1]">
    <xsl:if test="not(preceding-sibling::*)">[</xsl:if>
    <xsl:choose>
      <xsl:when test="not(child::node())">
        <xsl:text>null</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="child::node()"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">]</xsl:if>
  </xsl:template>
  
  <!-- convert root element to an anonymous container -->
  <xsl:template match="/">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
    
</xsl:stylesheet>';

end get_xml_to_json_stylesheet;


function ref_cursor_to_json (p_ref_cursor in sys_refcursor,
                             p_max_rows in number := null,
                             p_skip_rows in number := null) return clob
as
  l_ctx         dbms_xmlgen.ctxhandle;
  l_num_rows    pls_integer;
  l_xml         xmltype;
  l_json        xmltype;
  l_returnvalue clob;
begin


  /*

  Purpose:    generate JSON from REF Cursor

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.01.2010  Created
  
  */

  l_ctx := dbms_xmlgen.newcontext (p_ref_cursor);
  
  dbms_xmlgen.setnullhandling (l_ctx, dbms_xmlgen.empty_tag);
  
  -- for pagination

  if p_max_rows is not null then
    dbms_xmlgen.setmaxrows (l_ctx, p_max_rows);
  end if;
  
  if p_skip_rows is not null then
    dbms_xmlgen.setskiprows (l_ctx, p_skip_rows);
  end if;
  
  -- get the XML content
  l_xml := dbms_xmlgen.getxmltype (l_ctx, dbms_xmlgen.none);
  
  l_num_rows := dbms_xmlgen.getnumrowsprocessed (l_ctx);
  
  dbms_xmlgen.closecontext (l_ctx);
  
  close p_ref_cursor;

  if l_num_rows > 0 then
    -- perform the XSL transformation
    l_json := l_xml.transform (xmltype(get_xml_to_json_stylesheet));
    l_returnvalue := l_json.getclobval();
  else
    l_returnvalue := g_json_null_object;
  end if;

  l_returnvalue := dbms_xmlgen.convert (l_returnvalue, dbms_xmlgen.entity_decode);

  return l_returnvalue;

end ref_cursor_to_json;


function sql_to_json (p_sql in varchar2,
                      p_param_names in t_str_array := null,
                      p_param_values in t_str_array := null,
                      p_max_rows in number := null,
                      p_skip_rows in number := null) return clob
as
  l_ctx         dbms_xmlgen.ctxhandle;
  l_num_rows    pls_integer;
  l_xml         xmltype;
  l_json        xmltype;
  l_returnvalue clob;
begin

  /*

  Purpose:    generate JSON from SQL statement

  Remarks:    

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     30.01.2010  Created
  MBR     28.07.2010  Handle null value in bind variable value (issue and solution reported by Matt Nolan)
  
  */


  l_ctx := dbms_xmlgen.newcontext (p_sql);
  
  dbms_xmlgen.setnullhandling (l_ctx, dbms_xmlgen.empty_tag);
  
  -- bind variables, if any
  if p_param_names is not null then
  
    for i in 1..p_param_names.count loop
      dbms_xmlgen.setbindvalue (l_ctx, p_param_names(i), nvl(p_param_values(i), ''));
    end loop;
  
  end if;
  
  -- for pagination

  if p_max_rows is not null then
    dbms_xmlgen.setmaxrows (l_ctx, p_max_rows);
  end if;
  
  if p_skip_rows is not null then
    dbms_xmlgen.setskiprows (l_ctx, p_skip_rows);
  end if;
  
  -- get the XML content
  l_xml := dbms_xmlgen.getxmltype (l_ctx, dbms_xmlgen.none);
  
  l_num_rows := dbms_xmlgen.getnumrowsprocessed (l_ctx);
  
  dbms_xmlgen.closecontext (l_ctx);

  -- perform the XSL transformation
  if l_num_rows > 0 then
    l_json := l_xml.transform (xmltype(get_xml_to_json_stylesheet));
    l_returnvalue := l_json.getclobval();
    l_returnvalue := dbms_xmlgen.convert (l_returnvalue, dbms_xmlgen.entity_decode);
  else
    l_returnvalue := g_json_null_object;
  end if;
  
  return l_returnvalue;

end sql_to_json;


end json_util_pkg;
/

