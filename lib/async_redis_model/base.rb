require "#{File.dirname(__FILE__)}/serialization"
require "#{File.dirname(__FILE__)}/attributes"
require "#{File.dirname(__FILE__)}/persistence"
require "#{File.dirname(__FILE__)}/indexes"

module AsyncRedisModel
  class Base
    include AsyncRedisModel::Serialization
    include AsyncRedisModel::Attributes
    include AsyncRedisModel::Persistence
    include AsyncRedisModel::Indexes

    include ActiveModel::Validations
    
    attr_accessor :id
    
    def initialize(attributes={})
      @attributes = {}
      attributes.each do |name, val|
        if name.to_sym == :id
          self.id = val
        else
          @attributes[name.to_sym] = val
        end
      end
    end
  end # Base
end # AsyncRedisModel