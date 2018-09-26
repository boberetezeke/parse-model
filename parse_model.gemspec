Gem::Specification.new do |s|
  s.name        = 'parse_model'
  s.version     = '0.0.1'
  s.date        = '2015-12-03'
  s.summary     = "An active record like library for parse"
  s.description = "This provides a subset of active record for a parse back end"
  s.authors     = ["Steve Tuckner"]
  s.email       = 'stevetuckner@gmail.com'
  s.files       = Dir["lib/*"]
  s.license     = 'MIT'

  s.add_dependency 'activesupport', '~> 4.0'
  s.add_dependency 'activemodel',   '~> 4.0'
end
