Gem::Specification.new do |s|
  s.name        = 'rest-cli'
  s.version     = '0.1.0'
  s.date        = '2012-06-22'
  s.summary     = "Base to build simple command line interfaces to REST web services"
  s.description = "Extend this class to quickly write an interface to your REST web service"
  s.authors     = ["Jay Buffington"]
  s.email       = 'me@jaybuff.com'
  s.files       = `git ls-files -- lib`.split("\n")

  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'json'
end
