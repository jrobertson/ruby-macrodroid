Gem::Specification.new do |s|
  s.name = 'ruby-macrodroid'
  s.version = '0.2.1'
  s.summary = 'Reads the exported JSON file from MacroDroid. #unofficialgem #experimental'
  s.authors = ['James Robertson']
  s.files = Dir['lib/ruby-macrodroid.rb']
  s.add_runtime_dependency('uuid', '~> 2.3', '>=2.3.9')  
  s.add_runtime_dependency('rxfhelper', '~> 0.9', '>=0.9.4')  
  s.signing_key = '../privatekeys/ruby-macrodroid.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/ruby-macrodroid'
end
