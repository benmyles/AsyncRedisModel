require "#{File.dirname(__FILE__)}/index"

module AsyncRedisModel
  class MissingIdError < RuntimeError; end
   
  module Indexes
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end
    
    module ClassMethods
      def define_index_on(attribute_name, opts={})
        @defined_indexes ||= {}
        @defined_indexes[attribute_name] = opts
      end
      
      def defined_indexes
        @defined_indexes || {}
      end
      
      def sorted_defined_indexes
        defined_indexes || {}.sort { |x,y| x[0] <=> y[0] }
      end
      
      def includes?(id, &blk)
        all_index.includes?(id) do |resp|
          blk.call(resp)
        end
      end
      
      alias :include? :includes?
      
      def remove_from_index(index_name, record_id, value)
        return false if value.blank?
        index = AsyncRedisModel::Index.new(:class_name => self.to_s, :name => index_name, :value => value)
        index.rem(record_id) { |resp| }
        true
      end
      
      def index_members(index_name, value, &blk)
        index = AsyncRedisModel::Index.new(:class_name => self.to_s, :name => index_name, :value => value)
        index.members { |resp| blk.call(resp) }
      end
      
      def index(index_name, value)
        AsyncRedisModel::Index.new(:class_name => self.to_s, :name => index_name, :value => value)
      end
      
      def all_index
        @all_index ||= index("All", "")
      end
    end # ClassMethods
    
    module InstanceMethods
      def save_indexes(&blk)
        self.class.defined_indexes.each do |index_name, opts|
          value = orig_attributes[index_name.to_sym]
          next if value.blank?
          self.class.index(index_name, value).add(self.id) { |resp| }
        end
        blk.call(true) # stub
      end
      
      def destroy_indexes(&blk)
        self.class.defined_indexes.each do |index_name, opts|
          value = orig_attributes[index_name.to_sym]
          next if value.blank?
          self.class.index(index_name, value).rem(self.id) { |resp| }
        end
        blk.call(true) # stub
      end
      
      protected
      
      def add_to_all_index(&blk)
        raise(MissingIdError) unless self.id
        self.class.all_index.add(self.id) { |resp| blk.call(resp) }
      end
      
      def remove_from_all_index(&blk)
        raise(MissingIdError) unless self.id
        self.class.all_index.rem(self.id) { |resp| blk.call(resp) }
      end
    end # InstanceMethods
  end # Indexes
end