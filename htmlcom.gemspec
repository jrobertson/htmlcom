Gem::Specification.new do |s|
  s.name = 'htmlcom'
  s.version = '0.2.2'
  s.summary = 'Generates HTML components and is designed for rendering ' + 
      'dynamic web pages from a web server.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/htmlcom.rb']
  s.add_runtime_dependency('jsmenubuilder', '~> 0.2', '>=0.3.1')
  s.add_runtime_dependency('jsajax_wizard', '~> 0.3', '>=0.3.0')
  s.add_runtime_dependency('xml_to_sliml', '~> 0.1', '>=0.1.1')
  s.add_runtime_dependency('nokogiri', '~> 1.10', '>=1.10.8')
  s.signing_key = '../privatekeys/htmlcom.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/htmlcom'
end
