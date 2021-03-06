module Barchart
  class Resource
    def self.initialize_from_array_response(resource_class, response)
      JSON.parse(response.body).map do |resource_json|
        resource_class.new(resource_json)
      end
    end

    # Define class-level instance variables for field types
    def self.datetime_fields
      @datetime_fields ||= []
    end

    def self.date_fields
      @date_fields ||= []
    end

    def self.set_datetime_fields(*fields)
      datetime_fields.concat(fields.map(&:to_sym))
    end

    def self.set_date_fields(*fields)
      date_fields.concat(fields.map(&:to_sym))
    end

    attr_reader :response_json, :struct

    def initialize(response)
      @response_json = response
      normalized_json = convert_hash_keys(@response_json)
      @struct = RecursiveOpenStruct.new(normalized_json, {recurse_over_arrays: true})
    end

    def as_json(options = {})
      @response_json
    end

    def method_missing(name, *args)
      name = name.to_sym
      value = @struct[name]
      parse_value(name, value)
    end

    def inspect
      @struct.inspect.gsub(/#<RecursiveOpenStruct/,"#<#{self.class.name}")
    end

  private

    def parse_value(name, value)
      if self.class.datetime_fields.include?(name) && value.is_a?(String)
        DateTime.parse(value)
      elsif self.class.date_fields.include?(name) && value.is_a?(String)
        Date.parse(value)
      else
        value
      end
    rescue
      value
    end

    def underscore_key(k)
      k.to_s.underscore.to_sym
    end

    def convert_hash_keys(value)
      case value
      when Array then value.map { |v| convert_hash_keys(v) }
      when Hash then Hash[value.map { |k, v| [underscore_key(k), convert_hash_keys(v)] }]
      else value
      end
    end
  end
end
