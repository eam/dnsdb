require 'rubygems'
require 'rest_client'
require 'json'

module RestClient
  class Resource::Json
    def initialize(url)
      @client = RestClient::Resource.new(url, :headers => {
        :accept => :json,
        :content_type => :json
      })
    end

    def get(resource, id=nil, params={})
      resource = [resource, id].join("/") if id
      @resp = @client[resource].get({ :params => params })
      parse @resp.body
    end

    def create(resource, obj)
      @resp = @client[resource].post(generate(obj))
      parse @resp.body
    end

    def delete(resource, id)
      resource = [resource, id].join("/")
      @resp = @client[resource].delete
      parse @resp.body
    end
    
    def update(resource, id, obj)
      resource = [resource, id].join("/") if id
      @resp = @client[resource].put(generate(obj))
      parse @resp.body
    end

    def response
      return @resp
    end

    private

    # if obj is a string, assume it is JSON (nothing to do)
    # otherwise, convert the ruby obj to a JSON string
    def generate(obj)
      unless obj.is_a? String
        obj = JSON.generate obj
      end
      return obj
    end
    
    def parse(content)
      unless content.nil? or content.empty?
        begin
          return JSON.parse(content)
        rescue Exception => e
          warn "Error: " + e.message + ".  Content was: " + content
        end
      end

      return ""
    end
  end
end
