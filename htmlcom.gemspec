Gem::Specification.new do |s|
  s.name = 'htmlcom'
  s.version = '0.2.7'
  s.summary = 'Generates HTML components and is designed for rendering ' + 
      'dynamic web pages from a web server.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/htmlcom.rb']
  s.add_runtime_dependency('jsmenubuilder', '~> 0.3', '>=0.3.4')
  s.add_runtime_dependency('jstreebuilder', '~> 0.2', '>=0.2.4')
  s.add_runtime_dependency('jsajax_wizard', '~> 0.3', '>=0.3.1')
  s.add_runtime_dependency('xml_to_sliml', '~> 0.1', '>=0.1.2')
  s.add_runtime_dependency('nokogiri', '~> 1.11', '>=1.11.1')
  s.signing_key = '../privatekeys/htmlcom.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/htmlcom'
end
