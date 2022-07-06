#!/usr/bin/env ruby

# file: htmlcom.rb

# description: Generates HTML components and is designed for rendering dynamic web pages from a web server.

require 'nokogiri'
require 'xml_to_sliml'
require 'jsajax_wizard'
require 'jsmenubuilder'
require 'jstreebuilder'
require 'rexle'
require 'rexle-builder'

# classes:

# Accordion
# Tabs (:tabs, :full_page_tabs)
# Tree
# Menu (:vertical_menu, :fixed_menu, sticky_nav, breadcrumb)
# Element # used by the HTML element
# InputElement # used by the HTML input element
# Dropdown # an HTML element
# Textarea # an HTML element
# FormBuilder

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

      def initialize(title, content: '', callback: nil, debug: false)
        @title, @content, @callback, @debug = title, content, callback, debug
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

    def initialize(type=:tabs, headings: [], xml: nil, debug: false)

      @type, @debug = type, debug
      @build = JsMenuBuilder.new(type, headings: headings)

      @active_tab = 1

      @tab = headings.map do |heading|
        Tab.new heading, content: "<h3>#{heading}</h3>",
            callback: self, debug: debug
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

      if @debug then
        puts 'inside ping; tabs: ' + tabs.inspect
        puts '@active_tab: ' + @active_tab.inspect
      end

      @build = JsMenuBuilder.new(@type, tabs: tabs,
                                 active: @active_tab, debug: @debug)

    end

    alias refresh ping

    def to_css()
      @build.to_css
    end

    def to_html()
      @build.to_html
    end

    def to_js()
      @build.to_js
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

    # hn = heading number
    def initialize(s, debug: false, hn: 2)
      jtb = JsTreeBuilder.new(:sidebar, {src: s, hn: hn, debug: debug})
      @html = jtb.to_webpage
    end

    def to_webpage()
      @html
    end

  end

  class Menu

    # current options
    # :vertical_menu, :fixed_menu, sticky_nav, breadcrumb
    #
    def initialize(type=:vertical_menu, links, debug: false)
      @jtb = JsMenuBuilder.new(type, {items: links, debug: debug})
    end

    def to_css()
      @jtb.to_css
    end

    def to_html()
      @jtb.to_html
    end

    def to_js()
      @jtb.to_js
    end

    def to_webpage()
      @jtb.to_webpage
    end

  end

  class MindWordsWidget

    def initialize(attributes)

      @attributes = {
        content: '',
        action: 'mwupdate',
        target: 'icontent'
      }.merge(attributes)

    end

    def input(params={})

      h = @attributes.merge(params)
      content = h[:content]
      action = h[:action]
      target = h[:target]

@html =<<EOF
<form action='#{action}' method='post' target='#{target}'>
  <textarea name='content' cols='30' rows='19'>
#{content}
  </textarea>
  <input type='submit' value='Submit'/>
</form>
EOF
      self

    end

    def to_html()
      @html
    end

  end

  class Element

    def initialize(obj)

      @doc = build(obj)
      puts '@doc.xml : ' + @doc.xml.inspect
      if @id then
        elem = @doc.root.element(@tag + '/' + @htmltag)
        puts 'elem: ' +elem.inspect
        elem.attributes[:name] = @id
        elem.attributes[:id] = @id
      end

    end

    def html_element()
      @doc.root.element(@tag + '/' + @htmltag)
    end

    def to_doc()
      @doc
    end

    def build(rawobj)
      obj = rawobj.is_a?(Hash) ? RexleBuilder.new(rawobj).to_a : rawobj
      Rexle.new(obj)
    end

  end

  class InputElement < Element

    def initialize(rawobj)

      if @label then

        obj = [{label: @label}, rawobj]
        super({@tag.to_sym => obj})
        @doc.root.element(@tag + '/label').attributes[:for] = @id

      else
        super({@tag.to_sym => rawobj})
      end

    end

  end

  class Dropdown < InputElement

    def initialize(rawoptions=[], options: rawoptions, label: nil, id: nil)

      @tag = 'dropdown'
      @htmltag = 'select'
      @id = id
      @label = label

      if options.is_a? Array then

        list = options.map {|option| {option: option}}
        super({_select: list})

        values = options.map(&:downcase)
        @doc.root.xpath('dropdown/select/option').each.with_index do |e,i|
          e.attributes[:value] = values[i]
        end

      elsif options.is_a? Hash then

        list = options.values.map {|option| {option: option}}
        values = options.keys
        super({_select: list})

        @doc.root.xpath('dropdown/select/option').each.with_index do |e,i|
          e.attributes[:value] = values[i]
        end


      end
    end
  end

  class Textarea < InputElement

    def initialize(value='', text: value, label: nil, id: nil)

      @tag = 'textarea'
      @htmltag = 'textarea'
      @id = id
      @label = label
      super({@tag.to_sym => text})

    end

  end

  class Form < Element

    def initialize(inputs=nil, id: nil, method: :get, action: '')

      @tag = 'form'
      @htmltag = 'form'
      @id = id

      super([:root, {}, [@tag,{}, [@htmltag, {}]]])
      form = @doc.root.element(@tag + '/' + @htmltag)
      form.add inputs if inputs
      form.attributes[:method] = method.to_s
      form.attributes[:action] = action

    end

  end


  # e.g. inputs = {txt: [:textarea], audiotype: [:dropdown, 'gsm'], voice: [:dropdown, 'Stuart']}
  #        options = {audiotype: ['gsm', 'wav'], voice: %w(Stuart Kirsty Andrew)}
  #
  # fb = HtmlCom::FormBuilder.new(inputs: inputs, options: options)
  # puts fb.to_html

  class FormBuilder



    def initialize(inputs: {}, options: {}, id: 'form1', method: :get, action: '', debug: false)

      @debug = debug

      h = inputs.map do |key, value|

        if debug then
          puts 'id: ' + key.inspect
          puts 'klass: ' + value.first.inspect
        end

        [key, [value.first]]
      end.to_h

      options.each do |key, value|
        h[key] << value
      end

      klass = {dropdown: HtmlCom::Dropdown, textarea: HtmlCom::Textarea}

      @form = HtmlCom::Form.new(id: id, method: method, action: action)

      h.each do |key, value|

        id = key
        type, content = value
        action = case type
        when :dropdown
          'Select'
        else
          'Enter'
        end

        obj = klass[type].new content, id: id, label: action + ' ' + id.to_s

        obj.to_doc.root.element(type.to_s).elements.each do |e|
          @form.html_element.add e
        end

      end
    end

    def to_doc()
      @form.to_doc
    end

    def to_html()
      @form.to_doc.root.xml pretty: true
    end

  end

end
