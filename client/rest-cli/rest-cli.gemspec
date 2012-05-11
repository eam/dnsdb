Gem::Specification.new do |s|
  s.name        = 'rest-cli'
  s.version     = '0.0.3'
  s.date        = '2012-04-28'
  s.summary     = "Base to build simple command line interfaces to REST web services"
  s.description = "Extend this class to quickly write an interface to your REST web service"
  s.authors     = ["Jay Buffington"]
  s.email       = 'me@jaybuff.com'
  s.files       = ["lib/rest-cli.rb", "lib/json-resource.rb"]

  s.add_dependency 'rest-client'
end
