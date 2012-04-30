# rest-cli

Quickly write a command line client to interface with REST webservices.

## Example

Say you have a `foo` web service that provides a CRUD interface to a `bar` 
resource.  With this gem you can create a command called `foo` that has these
contents:

  #!/usr/bin/ruby 

  require 'rubygems'
  require 'rest-cli'
  RestCli.new(ARGV).run  

Then you can interact with your web services like this:

  $ foo create bars --blonk "yada yada"

  $ foo get bars
  [
    {
      "id": 1,
      "blonk": "yada yada"
    }
  ]

  $ foo update bars 1 --blonk "ding dong"

  $ foo get bars 1
  {
    "id": 1,
    "blonk": "ding dong"
  }
  
  $ foo delete bars 1
  
  $ foo get bars
  []

Running with no arguments gives you a sensible help message

  $ foo
  missing or invalid action
  Usage: foo <action> <resource> [<id>] [--option ...] [--key value ...]

  Actions: create, get, update, delete

  Global Options:
      --help        print this usage message and exit
      --verbose     print debugging information
      --url <url>   the base url to preface all HTTP requests with
      
  All other key/value options are structured as a JSON object and sent as the body
  of the HTTP request.

You can customize this help message by overloading the `usage` method

## Configuration

`rest-cli` will read configuration from a yaml file in `~/.<command name>rc`.  
In our above this would be `~/.foorc`. `url` and `verbose` are currently the 
only valid options.  Here's an example:

  $ cat ~/.foorc
  # the base url to the web services foo is interacting with
  url: http://foo.example.com
  # how chatty we should be
  verbose: false
   
You can also specify `--url <url>` and `--verbose` on the command line.  Note
that these switches are reserved, so if your web service needs them as an arg,
you're out of luck.

## Customization

`rest-cli` allows you to pre-process the input and post-process the output.
This feature isn't really fleshed out yet, so if you want to use it, look at the
code.  
