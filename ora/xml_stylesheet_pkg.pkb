create or replace package body xml_stylesheet_pkg
as
 
  /*
 
  Purpose:      Package handles stylesheets for XML
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     10.05.2010  Created
 
  */
 
 
function get_default_xml_stylesheet_ie return varchar2
as
  l_returnvalue varchar2(32000);
begin
 
  /*
 
  Purpose:      get default XML stylesheet (based on IE stylesheet)
 
  Remarks:      formats XML the way it is displayed by default in IE
                see http://www.biglist.com/lists/xsl-list/archives/200303/msg00794.html
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     10.05.2010  Created
 
  */
 
  l_returnvalue := '<?xml version="1.0"?>
<!--
  IE5 default style sheet, provides a view of any XML document
  and provides the following features:
  - auto-indenting of the display, expanding of entity references
  - click or tab/return to expand/collapse
  - color coding of markup
  - color coding of recognized namespaces - xml, xmlns, xsl, dt

  This style sheet is available in IE5 in a compact form at the URL
  "res://msxml.dll/DEFAULTSS.xsl".  This version differs only in the
  addition of comments and whitespace for readability.

  Author:  Jonathan Marsh (jmarsh@xxxxxxxxxxxxx)
  Modified:   05/21/2001 by Nate Austin (naustin@xxxxxxxxxx), Converted to use XSLT rather than WD-xsl
              05/10/2010 by Morten Braten (http://ora-00001.blogspot.com), Cleaned up formatting, removed some comments to reduce size; see original post for original version
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dt="urn:schemas-microsoft-com:datatypes" xmlns:d2="uuid:C2F41010-65B3-11d1-A29F-00AA00C14882">

<xsl:template match="/">

        <STYLE>
        .st div, .st span, .st a { font-family:lucida console,courier; }
        .c  {cursor:hand;}
        .b  {font-family:Verdana,Tahoma, arial;text-decoration:none}
        .e  {margin-left:3em; text-indent:-1.5em; margin-top:1px; margin-right:1em}
        .k  {margin-left:1em; text-indent:-1em; margin-right:1em}
        .t  {color:black}
        .xt {color:dark;}
        .ns {color:#E8E8CD;}
        .dt {color:green}
        .m  {color:#2D599E}
        .tx {font-weight:bold;}
        .db {text-indent:0px; margin-left:1em;  margin-top:0px; margin-bottom:0px; padding-left:.3em; border-left:1px solid #CCCCCC; font:small Courier}
        .di {font:small Courier}
        .d  {color:#2D599E}
        .pi {color:#2D599E}
        .cb {text-indent:0px; margin-left:1em; margin-top:0px;margin-bottom:0px; padding-left:.3em; font:small Courier; color:#888888}
        .ci {font:small Courier; color:#888888}
        PRE {margin:0px; display:inline}
      </STYLE>
        <SCRIPT>
          <xsl:comment><![CDATA[
        // Detect and switch the display of CDATA and comments from an inline view
        //  to a block view if the comment or CDATA is multi-line.
        function f(e)
        {
          // if this element is an inline comment, and contains more than a single
          //  line, turn it into a block comment.
          if (e.className == "ci") {
            if (e.children(0).innerText.indexOf("\n") > 0)
              fix(e, "cb");
          }
          
          // if this element is an inline cdata, and contains more than a single
          //  line, turn it into a block cdata.
          if (e.className == "di") {
            if (e.children(0).innerText.indexOf("\n") > 0)
              fix(e, "db");
          }
          
          // remove the id since we only used it for cleanup
          e.id = "";
        }
        
        // Fix up the element as a "block" display and enable expand/collapse on it
        function fix(e, cl)
        {
          // change the class name and display value
          e.className = cl;
          e.style.display = "block";
     
          // mark the comment or cdata display as a expandable container
          j = e.parentElement.children(0);
          j.className = "c";

          // find the +/- symbol and make it visible - the dummy link enables tabbing
          k = j.children(0);
          k.style.visibility = "visible";
          k.href = "#";
        }

        // Change the +/- symbol and hide the children.  This function works on "element"
        //  displays
        function ch(e)
        {
          // find the +/- symbol
          mark = e.children(0).children(0);
          
          // if it is already collapsed, expand it by showing the children
          if (mark.innerText == "+")
          {
            mark.innerText = "-";
            for (var i = 1; i < e.children.length; i++)
              e.children(i).style.display = "block";
          }
          
          // if it is expanded, collapse it by hiding the children
          else if (mark.innerText == "-")
          {
            mark.innerText = "+";
            for (var i = 1; i < e.children.length; i++)
              e.children(i).style.display="none";
          }
        }
        
        // Change the +/- symbol and hide the children.  This function work on "comment"
        //  and "cdata" displays
        function ch2(e)
        {
          // find the +/- symbol, and the "PRE" element that contains the content
          mark = e.children(0).children(0);
          contents = e.children(1);
          
          // if it is already collapsed, expand it by showing the children
          if (mark.innerText == "+")
          {
            mark.innerText = "-";
            // restore the correct "block"/"inline" display type to the PRE
            if (contents.className == "db" || contents.className == "cb")
              contents.style.display = "block";
            else contents.style.display = "inline";
          }
          
          // if it is expanded, collapse it by hiding the children
          else if (mark.innerText == "-")
          {
            mark.innerText = "+";
            contents.style.display = "none";
          }
        }
        
        // Handle a mouse click
        function cl()
        {
          e = window.event.srcElement;
          
          // make sure we are handling clicks upon expandable container elements
          if (e.className != "c")
          {
            e = e.parentElement;
            if (e.className != "c")
            {
              return;
            }
          }
          e = e.parentElement;
          
          // call the correct funtion to change the collapse/expand state and display
          if (e.className == "e")
            ch(e);
          if (e.className == "k")
            ch2(e);
        }

        // Dummy function for expand/collapse link navigation - trap onclick events instead
        function ex() 
        {}

        // Erase bogus link info from the status window
        function h()
        {
          window.status=" ";
        }

        // Set the onclick handler
        document.onclick = cl;
        
      ]]></xsl:comment>
				</SCRIPT>

			<div class="st">
	
				<xsl:apply-templates/>

     </div>

</xsl:template>

<!-- Templates for each node type follows.  The output of each template has a similar structure to enable script to walk the result tree easily for handling user interaction. -->
<!-- Template for the DOCTYPE declaration.  No way to get
      the DOCTYPE, so we just put in a placeholder -->
<!--  no support for doctypes
<xsl:template match="node()[nodeType()=10]">
  <DIV class="e"><SPAN>
  <SPAN class="b">&#160;</SPAN>
  <SPAN class="d">&lt;!DOCTYPE <xsl:value-of select="name()"/><I> (View Source for full doctype...)</I>&gt;</SPAN>
  </SPAN></DIV>
</xsl:template>
-->
<!-- Template for pis not handled elsewhere -->
    <xsl:template match="processing-instruction()">
        <DIV class="e">
            <SPAN class="b">&#160;</SPAN>
            <SPAN class="m">&lt;?</SPAN>
            <SPAN class="pi">
            <xsl:value-of select="name()" />&#160;<xsl:value-of select="." />
            </SPAN>
            <SPAN class="m">?&gt;</SPAN>
        </DIV>
    </xsl:template>

<!-- Template for the XML declaration.  Need a separate template because the
pseudo-attributes are actually exposed as attributes instead of just element content,
as in other pis -->
<!--  No support for the xml declaration
<xsl:template match="pi(''xml'')">
  <DIV class="e">
  <SPAN class="b">&#160;</SPAN>
  <SPAN class="m">&lt;?</SPAN><SPAN class="pi">xml
      <xsl:for-each select="@*"><xsl:value-of select="name()"/>="<xsl:value-of select="."/>"
</xsl:for-each></SPAN><SPAN class="m">?&gt;</SPAN>
  </DIV>
</xsl:template>
-->
<!-- Template for attributes not handled elsewhere -->
<xsl:template match="@*" xml:space="preserve">
<SPAN>
<xsl:attribute name="class">
  <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>t</xsl:attribute>
<xsl:value-of select="name()" />
</SPAN>

<SPAN class="m">=&quot;</SPAN>
<B>
  <xsl:value-of select="." />
</B>

<SPAN class="m">&quot;</SPAN>
</xsl:template>

<!-- Template for attributes in the xmlns or xml namespace -->
<!--  UNKNOWN
<xsl:template match="@xmlns:*|@xmlns|@xml:*"><SPAN class="ns"> <xsl:value-of select="name()"/></SPAN><SPAN class="m">="</SPAN>
  <B class="ns"><xsl:value-of select="."/></B><SPAN class="m">"</SPAN></xsl:template>
-->
<!-- Template for attributes in the dt namespace -->
<!-- UNKNOWN
<xsl:template match="@dt:*|@d2:*"><SPAN class="dt"> <xsl:value-of select="name()"/></SPAN><SPAN class="m">="</SPAN><B class="dt">
<xsl:value-of select="."/></B><SPAN class="m">"</SPAN>
</xsl:template>
-->
<!-- Template for text nodes -->
    <xsl:template match="text()">
        <DIV class="e">
            <SPAN class="b">&#160;</SPAN>
            <SPAN class="tx">
                <xsl:value-of select="." />
            </SPAN>
        </DIV>
    </xsl:template>

<!-- Template for comment nodes -->
    <xsl:template match="comment()">
        <DIV class="k">
            <SPAN>
                <A class="b" onclick="return false" onfocus="h()" STYLE="visibility:hidden">-</A>
                <SPAN class="m">&lt;!--</SPAN>
            </SPAN>
            <SPAN id="clean" class="ci">
      <PRE>
<xsl:value-of select="." />
</PRE>
            </SPAN>
            <SPAN class="b">&#160;</SPAN>
            <SPAN class="m">--&gt;</SPAN>

<SCRIPT>
f(clean);
</SCRIPT>
        </DIV>
    </xsl:template>

<!-- Template for cdata nodes -->
<!-- UNSUPPORTED
<xsl:template match="cdata()">
  <DIV class="k">
  <SPAN><A class="b" onclick="return false" onfocus="h()"
STYLE="visibility:hidden">-</A> <SPAN class="m">
      &lt;![CDATA[</SPAN></SPAN>
  <SPAN id="clean" class="di"><PRE><xsl:value-of
      select="."/></PRE></SPAN>
  <SPAN class="b">&#160;</SPAN> <SPAN
      class="m">]]&gt;</SPAN>
  <SCRIPT>f(clean);</SCRIPT></DIV>
</xsl:template>
-->
<!-- Template for elements not handled elsewhere (leaf nodes) -->
    <xsl:template match="*">
        <DIV class="e">
            <DIV STYLE="margin-left:1em;text-indent:-2em">
                <SPAN class="b">&#160;</SPAN>
                <SPAN class="m">&lt;</SPAN>
                <SPAN>
                    <xsl:attribute name="class">
                    <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>
                    t</xsl:attribute>
                    <xsl:value-of select="name()" />
                </SPAN>
                <xsl:apply-templates select="@*" />
                <SPAN class="m">/&gt;</SPAN>
            </DIV>
        </DIV>
    </xsl:template>

<!-- Template for elements with comment, pi and/or cdata children -->
    <xsl:template match="*[comment() | processing-instruction()]">
        <DIV class="e">
            <DIV class="c">
                <A href="#" onclick="return false" onfocus="h()" class="b">-</A>
                <SPAN class="m">&lt;</SPAN>
                <SPAN>
                    <xsl:attribute name="class">
                    <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>t</xsl:attribute>
                    <xsl:value-of select="name()" />
                </SPAN>
                <xsl:apply-templates select="@*" />
                <SPAN class="m">&gt;</SPAN>
            </DIV>
            <DIV>
                <xsl:apply-templates />
                <DIV>
                    <SPAN class="b">&#160;</SPAN>
                    <SPAN class="m">&lt;/</SPAN>
                    <SPAN>
                        <xsl:attribute name="class">
                        <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>t</xsl:attribute>
                        <xsl:value-of select="name()" />
                    </SPAN>
                    <SPAN class="m">&gt;</SPAN>
                </DIV>
            </DIV>
        </DIV>
    </xsl:template>

<!-- Template for elements with only text children -->
    <xsl:template match="*[text() and not(comment() | processing-instruction())]">
        <DIV class="e">
            <DIV STYLE="margin-left:1em;text-indent:-2em">
                <SPAN class="b">&#160;</SPAN>
                <SPAN class="m">&lt;</SPAN>
                <SPAN>
                    <xsl:attribute name="class">
                    <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>t</xsl:attribute>
                    <xsl:value-of select="name()" />
                </SPAN>
                <xsl:apply-templates select="@*" />
                <SPAN class="m">&gt;</SPAN>
                <SPAN class="tx">
                    <xsl:value-of select="." />
                </SPAN>
                <SPAN class="m">&lt;/</SPAN>
                <SPAN>
                    <xsl:attribute name="class">
                    <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>t</xsl:attribute>
                    <xsl:value-of select="name()" />
                </SPAN>
                <SPAN class="m">&gt;</SPAN>
            </DIV>
        </DIV>
    </xsl:template>

<!-- Template for elements with element children -->
    <xsl:template match="*[*]">
        <DIV class="e">
            <DIV class="c" STYLE="margin-left:1em;text-indent:-2em;">
                <A href="#" onclick="return false" onfocus="h()" class="b">+</A>
                <SPAN class="m">&lt;</SPAN>
                <SPAN>
                    <xsl:attribute name="class">
                    <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>t</xsl:attribute>
                    <xsl:value-of select="name()" />
                </SPAN>
                <xsl:apply-templates select="@*" />
                <SPAN class="m">&gt;</SPAN>
            </DIV>
            <DIV style="display:none;">
                <xsl:apply-templates />
                <DIV>
                    <SPAN class="b">&#160;</SPAN>
                    <SPAN class="m">&lt;/</SPAN>
                    <SPAN>
                        <xsl:attribute name="class">
                        <xsl:if test="starts-with(name(),&#39;xsl:&#39;)">x</xsl:if>t</xsl:attribute>
                        <xsl:value-of select="name()" />
                    </SPAN>
                    <SPAN class="m">&gt;</SPAN>
                </DIV>
            </DIV>
        </DIV>
    </xsl:template>
</xsl:stylesheet>';  

  return l_returnvalue;
 
end get_default_xml_stylesheet_ie;


function get_default_xml_stylesheet_ff return varchar2
as
  l_returnvalue varchar2(32000);
begin
 
  /*
 
  Purpose:      get default XML stylesheet (based on FF stylesheet)
 
  Remarks:      formats XML the way it is displayed by default in FF
                see http://forums.mozillazine.org/viewtopic.php?f=38&t=293645
                    chrome://global/content/xml/XMLPrettyPrint.xsl
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.02.2011  Created
 
  */
 
  l_returnvalue := '<?xml version="1.0"?>
<!-- ***** BEGIN LICENSE BLOCK *****
   - Version: MPL 1.1/GPL 2.0/LGPL 2.1
   -
   - The contents of this file are subject to the Mozilla Public License Version
   - 1.1 (the "License"); you may not use this file except in compliance with
   - the License. You may obtain a copy of the License at
   - http://www.mozilla.org/MPL/
   -
   - Software distributed under the License is distributed on an "AS IS" basis,
   - WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
   - for the specific language governing rights and limitations under the
   - License.
   -
   - The Original Code is mozilla.org code.
   -
   - The Initial Developer of the Original Code is
   - Netscape Communications Corporation.
   - Portions created by the Initial Developer are Copyright (C) 2002
   - the Initial Developer. All Rights Reserved.
   -
   - Contributor(s):
   -   Jonas Sicking <sicking@bigfoot.com> (Original author)
   -
   - Alternatively, the contents of this file may be used under the terms of
   - either the GNU General Public License Version 2 or later (the "GPL"), or
   - the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
   - in which case the provisions of the GPL or the LGPL are applicable instead
   - of those above. If you wish to allow use of your version of this file only
   - under the terms of either the GPL or the LGPL, and not to allow others to
   - use your version of this file under the terms of the MPL, indicate your
   - decision by deleting the provisions above and replace them with the notice
   - and other provisions required by the LGPL or the GPL. If you do not delete
   - the provisions above, a recipient may use your version of this file under
   - the terms of any one of the MPL, the GPL or the LGPL.
   -
   - ***** END LICENSE BLOCK ***** -->


<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml"/>

  <xsl:template match="/">
    <link href="chrome://global/content/xml/XMLPrettyPrint.css" type="text/css" rel="stylesheet"/>

    <link title="Monospace" href="chrome://global/content/xml/XMLMonoPrint.css" type="text/css" rel="alternate stylesheet"/>
    <!--<div id="header" dir="ltr">
      <p>
        This XML file does not appear to have any style information associated with it. The document tree is shown below.
      </p>
    </div>-->
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="*">
    <div>
      <xsl:text>&lt;</xsl:text>
      <span class="start-tag"><xsl:value-of select="name(.)"/></span>
      <xsl:apply-templates select="@*"/>
      <xsl:text>/&gt;</xsl:text>
    </div>
  </xsl:template>

  <xsl:template match="*[node()]">
    <div>
      <xsl:text>&lt;</xsl:text>
      <span class="start-tag"><xsl:value-of select="name(.)"/></span>
      <xsl:apply-templates select="@*"/>
      <xsl:text>&gt;</xsl:text>

      <span class="text"><xsl:value-of select="."/></span>

      <xsl:text>&lt;/</xsl:text>
      <span class="end-tag"><xsl:value-of select="name(.)"/></span>
      <xsl:text>&gt;</xsl:text>
    </div>
  </xsl:template>

  <xsl:template match="*[* or processing-instruction() or comment() or string-length(.) &gt; 50]">
    <div class="expander-open">
      <xsl:call-template name="expander"/>

      <xsl:text>&lt;</xsl:text>
      <span class="start-tag"><xsl:value-of select="name(.)"/></span>
      <xsl:apply-templates select="@*"/>
      <xsl:text>&gt;</xsl:text>

      <div class="expander-content"><xsl:apply-templates/></div>

      <xsl:text>&lt;/</xsl:text>
      <span class="end-tag"><xsl:value-of select="name(.)"/></span>

      <xsl:text>&gt;</xsl:text>
    </div>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:text> </xsl:text>
    <span class="attribute-name"><xsl:value-of select="name(.)"/></span>
    <xsl:text>=</xsl:text>

    <span class="attribute-value">"<xsl:value-of select="."/>"</span>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:if test="normalize-space(.)">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="processing-instruction()">
    <div class="pi">
      <xsl:text>&lt;?</xsl:text>
      <xsl:value-of select="name(.)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>?&gt;</xsl:text>

    </div>
  </xsl:template>

  <xsl:template match="processing-instruction()[string-length(.) &gt; 50]">
    <div class="expander-open">
      <xsl:call-template name="expander"/>

      <span class="pi">
        <xsl:text> &lt;?</xsl:text>

        <xsl:value-of select="name(.)"/>
      </span>
      <div class="expander-content pi"><xsl:value-of select="."/></div>
      <span class="pi">
        <xsl:text>?&gt;</xsl:text>
      </span>
    </div>
  </xsl:template>

  <xsl:template match="comment()">
    <div class="comment">
      <xsl:text>&lt;!--</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>--&gt;</xsl:text>
    </div>
  </xsl:template>

  <xsl:template match="comment()[string-length(.) &gt; 50]">
    <div class="expander-open">
      <xsl:call-template name="expander"/>

      <span class="comment">
        <xsl:text>&lt;!--</xsl:text>
      </span>
      <div class="expander-content comment">

        <xsl:value-of select="."/>
      </div>
      <span class="comment">
        <xsl:text>--&gt;</xsl:text>
      </span> 
    </div>
  </xsl:template>
  
  <xsl:template name="expander">
    <div class="expander">&#x2212;</div>

  </xsl:template>

</xsl:stylesheet>';

  return l_returnvalue;

end get_default_xml_stylesheet_ff;


function transform (p_xml in xmltype,
                    p_stylesheet in xmltype := null) return xmltype
as
  l_returnvalue xmltype;
begin

  /*
 
  Purpose:      transform XML via stylesheet
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_returnvalue := p_xml.transform (coalesce(p_stylesheet, xmltype(get_default_xml_stylesheet_ie)));

  return l_returnvalue;

end transform;


function transform_clob (p_clob in clob,
                         p_stylesheet in clob := null) return clob
as
  l_xml         xmltype;
  l_returnvalue clob;
begin

  /*
 
  Purpose:      transform XML via stylesheet (clob version)
 
  Remarks:      
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     22.01.2011  Created
 
  */
  
  l_xml := xmltype (p_clob);

  l_xml := l_xml.transform (xmltype(nvl(p_stylesheet, get_default_xml_stylesheet_ie)));

  l_returnvalue := l_xml.getclobval();

  return l_returnvalue;

end transform_clob;


 
end xml_stylesheet_pkg;
/
 


