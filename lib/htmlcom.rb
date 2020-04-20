#!/usr/bin/env ruby

# file: htmlcom.rb

# description: Generates HTML components and is designed for rendering dynamic web pages from a web server.

require 'nokogiri'
require 'xml_to_sliml'
require 'jsajax_wizard'
require 'jsmenubuilder'
require 'jstreebuilder'


module HtmlCom    
  
  class Accordion
    
    attr_reader :to_html, :to_css, :to_js, :to_tags
    
    def initialize(xml, debug: false)
      
      xml, @debug = xml, debug
      
      # transform the accordion XML to tags XML
      tags = Nokogiri::XSLT(xsl()).transform(Nokogiri::XML(xml))\
          .to_xhtml(indent: 0)
      
      @to_tags = tags # used for debugging the structure
      
      jmb = JsMenuBuilder.new(tags, debug: debug)
      
      pg = if Rexle.new(xml).root.attributes[:navbar] then

        a = jmb.to_h.keys.sort.map {|key, _| [key, '#' + key.downcase]}

        navbar = JsMenuBuilder.new(:sticky_navbar, {sticky_navbar: a, 
                                                    debug: debug})
        
        @to_css = navbar.to_css + "\n" + jmb.to_css
        @to_js = navbar.to_js + "\n" + jmb.to_js


        jmb.to_webpage do |css, html, js|
          
          [
            navbar.to_css + "\n" + css, 
            navbar.to_html + "\n" + html, 
            navbar.to_js + "\n" + js
          ]
          
        end
        
      else
        
        @to_css = jmb.to_css
        @to_js = jmb.to_js
      
        jmb.to_webpage
        
      end

      # apply the AJAX
      @to_html = JsAjaxWizard.new(pg).to_html      

    end
    
    
    private

    def xsl()
      
xsl= %q(
    <xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='1.0'>

  <xsl:template match='accordion'>

    <xsl:element name='tags'>
      <xsl:attribute name='mode'>accordion</xsl:attribute>  
      <xsl:apply-templates select='panel' />
    </xsl:element>

  </xsl:template>

  <xsl:template match='panel'>

    <xsl:element name='tag'>
      <xsl:attribute name='title'>
        <xsl:value-of select='@title'/>
      </xsl:attribute>
      
      <xsl:attribute name='class'>
        <xsl:value-of select='@class'/>
      </xsl:attribute>      

      <xsl:element name="input">
        <xsl:attribute name="type">hidden</xsl:attribute>

        <xsl:if test='@onopen!=""'>
          <xsl:attribute name="onclick"><xsl:value-of select="@onopen"/></xsl:attribute>
        </xsl:if>
        <xsl:if test='@onclose!=""'>
          <xsl:attribute name="ondblclick"><xsl:value-of select="@onclose"/></xsl:attribute>
        </xsl:if>
      </xsl:element>

      <xsl:copy-of select="*"/>
      <xsl:if test='@ajaxid!=""'> <!-- used with onopen -->
        <div id='{@ajaxid}'>$<xsl:value-of select="@ajaxid"/></div>
      </xsl:if>

    </xsl:element>

  </xsl:template>


</xsl:stylesheet>
)

    end
    
  end

  class Tabs

    class Tab

      attr_accessor :title, :content

      def initialize(title, content: '', callback: nil)
        @title, @content, @callback = title, content, callback
      end

      def content=(s)
        @content = s
        @callback.ping
      end

      def delete()
        @title = nil
        @callback.ping
      end

      def title=(s)
        @title = s
        @callback.ping
      end

      def to_a()
        [@title, @content]
      end

    end

    attr_reader :tab, :active

    # current options for type:
    #   :tabs, :full_page_tabs
    
    def initialize(type=:tabs, headings: [], xml: nil)

      @type = type
      @build = JsMenuBuilder.new(type, headings: headings)

      @tab = headings.map do |heading|
        Tab.new heading, content: "<h3>#{heading}</h3>", callback: self
      end

      if xml then
        @build.import(xml)
      end

    end

    def active=(tabnum)
      @active_tab = tabnum
      refresh()
    end

    def add_tab(title, content: '', index: nil)

      tab = Tab.new(title, content: content)

      if index then
        @tab.insert index, tab
      else
        @tab << tab
      end

      refresh()

    end

    def delete_tab(i)
      @tab.delete i
      refresh()
    end

    def ping()

      tabs = @tab.map do |tab|
        tab.title ? tab.to_a : nil
      end.compact.to_h

      @build = JsMenuBuilder.new(@type, tabs: tabs, active: @active_tab)

    end

    alias refresh ping

    def to_html()
      @build.to_html
    end


    # not yet working properly
    def to_bangtag()
      XmlToSliml.new(@build.to_xml, spacer: '!')\
          .to_s.lines.map {|x| '!' + x }.join
    end

    def to_webpage()
      @build.to_webpage
    end

  end
  
  class Tree
    
    def initialize(s, debug: false, hn: 2)
      jtb = JsTreeBuilder.new(:sidebar, {src: s, hn: hn, debug: debug})
      @html = jtb.to_webpage      
    end
    
    def to_webpage()
      @html
    end
    
  end

end
