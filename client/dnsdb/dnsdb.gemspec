Gem::Specification.new do |s|
  s.name        = 'dnsdb'
  s.version     = '0.0.3'
  s.date        = '2012-05-10'
  s.summary     = "ruby client and cli for DNSDB"
  s.description = "ruby client and command line interface for CRUD operations into DNSDB"
  s.authors     = ["Jay Buffington"]
  s.email       = 'me@jaybuff.com'

  s.files       = ["lib/dnsdb-cli.rb", "lib/dnsdb.rb"]

  s.add_dependency 'rest-cli'
  s.executables << 'dnsdb'
end
