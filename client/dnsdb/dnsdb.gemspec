require 'dnsdb-cli'

Gem::Specification.new do |s|
  s.name        = 'dnsdb-cli'
  s.version     = DnsdbCli::VERSION
  s.date        = '2012-04-28'
  s.summary     = "cli for DNSDB"
  s.description = "Command line interface for CRUD operations into DNSDB"
  s.authors     = ["Jay Buffington"]
  s.email       = 'me@jaybuff.com'

  s.files       = ["lib/dnsdb-cli.rb"]

  s.add_dependency 'rest-cli'
  s.executables << 'dnsdb'
end
