require 'yaml'
require 'cgi'

module AsyncRedisModel
  module Serialization
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end
    
    module ClassMethods
      def encoded_value(obj)
        CGI.escape YAML.dump(obj)
      end
      
      def decoded_value(str)
        YAML.load(CGI.unescape str)
      end
    end # ClassMethods
    
    module InstanceMethods
      def encoded_value(obj)
        self.class.encoded_value(obj)
      end
      
      def decoded_value(str)
        if str.blank?
          return nil
        else
          self.class.decoded_value(str.to_s)
        end
      end
    end # InstanceMethods
  end # Serialization
end # AsyncRedisModel