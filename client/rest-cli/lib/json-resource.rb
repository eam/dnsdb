require 'rubygems'
require 'rest_client'
require 'json'

module RestClient
  class Resource::Json
    def initialize(url)
      @client = RestClient::Resource.new(url, {
        :raw_response => true,
        :headers => {
          :accept => :json,
          :content_type => :json
        }
      })
    end

    def process_response(body, res, request)
        @resp = Response.create(Request.decode(res['content-encoding'], body), res, request.args)
        return parse body
    end

    def get(resource, id=nil, params={})
      resource = [resource, id].join("/") if id
      @client[resource].get({ :params => params }) do |raw_response, request, res|
        return process_response raw_response.to_s, res, request
      end
    end

    def create(resource, obj)
      @client[resource].post(generate(obj)) do |raw_response, request, res|
        return process_response raw_response.to_s, res, request
      end
    end

    def delete(resource, id)
      resource = [resource, id].join("/")
      @client[resource].delete do |raw_response, request, res|
        return process_response raw_response.to_s, res, request
      end
    end

    def update(resource, id, obj)
      resource = [resource, id].join("/") if id
      @client[resource].put(generate(obj)) do |raw_response, request, res|
        return process_response raw_response.to_s, res, request
      end
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
      unless content.nil? or content.match(/^\s*$/)
        begin
          return JSON.parse(content)
        rescue JSON::ParserError => e
          warn "Error: " + e.message + ".  Content was: " + content
        end
      end

      nil
    end
  end
end
