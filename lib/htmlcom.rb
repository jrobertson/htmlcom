#!/usr/bin/env ruby

# file: htmlcom.rb

# description: Generates HTML components and is designed for rendering dynamic web pages from a web server.

require 'jsmenubuilder'


module HtmlCom

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
    
    def initialize(type=:tabs, headings: %w(tab1 tab2 tab3))

      @type = type
      @build = JsMenuBuilder.new(type, headings: headings)

      @tab = headings.map do |heading|
        Tab.new heading, content: "<h3>#{heading}</h3>", callback: self
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

    def to_webpage()
      @build.to_webpage
    end

  end

end
