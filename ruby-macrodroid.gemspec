Gem::Specification.new do |s|
  s.name = 'ruby-macrodroid'
  s.version = '0.8.12'
  s.summary = 'A macro builder for MacroDroid. #unofficialgem #experimental'
  s.authors = ['James Robertson']
  s.files = Dir[
    'lib/ruby-macrodroid.rb', 
    'lib/ruby-macrodroid/base.rb', 
    'lib/ruby-macrodroid/triggers.rb', 
    'lib/ruby-macrodroid/actions.rb', 
    'lib/ruby-macrodroid/triggers.rb',
    'lib/ruby-macrodroid/constraints.rb',
    'lib/ruby-macrodroid/macro.rb'
  ]
  s.add_runtime_dependency('glw', '~> 0.2', '>=0.2.2')    
  s.add_runtime_dependency('uuid', '~> 2.3', '>=2.3.9')
  s.add_runtime_dependency('rowx', '~> 0.7', '>=0.7.0')
  s.add_runtime_dependency('subunit', '~> 0.7', '>=0.7.0')
  s.add_runtime_dependency('geozone', '~> 0.1', '>=0.1.0')  
  s.add_runtime_dependency('rxfhelper', '~> 1.1', '>=1.1.1')
  s.add_runtime_dependency('chronic_cron', '~> 0.6', '>=0.6.0')
  s.signing_key = '../privatekeys/ruby-macrodroid.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/ruby-macrodroid'
end
