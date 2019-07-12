# Introducing the htmlcom gem

    require 'htmlcom'

    tabs = HtmlCom::Tabs.new headings: %w(London Paris Dublin)

    tabs.tab[0].content = '<p>Hello!</p>'
    tabs.tab[1].content = '<p>Tab 2</p>'
    #tabs.tab[1].delete
    #tabs.delete_tab 1
    tabs.add_tab 'Russia', content: '<p>Tab 4</p>'
    puts tabs.to_html
    #tabs.active = '3'
    tabs.active = '2'
    File.write '/tmp/foo.html', tabs.to_webpage
    `firefox /tmp/foo.html &`

The above example demonstrates how to change the content of 1 or more tabs rendered in HTML dynamically using Ruby.

## Resources

* htmlcom https://rubygems.org/gems/htmlcom

htmlcom html component tab tabs jsmenubuilder
