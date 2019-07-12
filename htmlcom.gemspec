Gem::Specification.new do |s|
  s.name = 'htmlcom'
  s.version = '0.1.0'
  s.summary = 'Generates HTML components and is designed for rendering dynamic web pages from a web server.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/htmlcom.rb']
  s.add_runtime_dependency('jsmenubuilder', '~> 0.1', '>=0.1.1')
  s.signing_key = '../privatekeys/htmlcom.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/htmlcom'
end
