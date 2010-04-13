module AsyncRedisModel  
  module Attributes
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end
    
    module ClassMethods
      def key_for_attribute(id, name)
        ["AsyncRedisModel",self.to_s,id,name].join(":")
      end
      
      def define_attribute(name, opts={})
        @defined_attributes ||= {}
        @defined_attributes[name] = opts
        define_method(name) do
          @attributes ||= {}
          @attributes[name.to_sym]
        end
        define_method("#{name}=") do |val|
          @attributes ||= {}
          @attributes[name.to_sym] = val
        end
        true
      end
      
      def defined_attributes
        @defined_attributes || {}
      end
      
      def sorted_defined_attributes
        defined_attributes.sort { |x,y| x[0] <=> y[0] }
      end
    end
    
    module InstanceMethods
      def attributes
        @attributes || {}
      end
      
      def orig_attributes
        @orig_attributes || {}
      end
      
      def key_for_attribute(name)
        return nil unless self.id
        self.class.key_for_attribute(self.id, name)
      end
      
      def attribute_keys
        self.class.sorted_defined_attributes.collect { |name, opts| key_for_attribute(name) }.flatten
      end
      
      def attribute_names
        self.class.sorted_defined_attributes.collect { |name, opts| name }
      end
    end # InstanceMethods
  end # Attributes
end # AsyncRedisModel