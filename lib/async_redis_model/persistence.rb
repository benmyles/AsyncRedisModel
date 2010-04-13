module AsyncRedisModel
  class RecordNotNewError   < RuntimeError; end
  class RecordIsNewError    < RuntimeError; end
  class RecordNotValidError < RuntimeError; end
  class RecordNotFoundError < RuntimeError; end
  
  module Persistence
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end
    
    module ClassMethods
    end
    
    module InstanceMethods
      def new_record?
        @new_record.nil? ? true : @new_record
      end

      def new_record=(val)
        @new_record = val
      end

      def create(&blk)
        raise(AsyncRedisModel::RecordNotNewError) unless new_record?
        raise(AsyncRedisModel::RecordNotValidError) unless valid?
        save(true) do |resp|
          if resp
            add_to_all_index { |resp| } # no need to block
          end
          blk.call(resp)
        end
      end

      def save(force=false, &blk)
        raise(AsyncRedisModel::RecordIsNewError, "use create") if new_record? and !force
        raise(AsyncRedisModel::RecordNotValidError) unless valid? || force
        AsyncRedisModel.client.mset(*kv_pairs_for_mset) do |resp|
          if resp
            self.new_record = false
            destroy_indexes { |resp| } # no need to block
            @orig_attributes = @attributes.dup
            save_indexes { |resp| } # no need to block
            blk.call(true)
          else
            blk.call(false)
          end
        end # mset
      end

      def destroy(&blk)
        return false unless valid?
        return false if new_record?
        destroy_indexes { |resp| } # no need to block
        remove_from_all_index { |resp| } # no need to block
        attribute_keys.each do |key|
          AsyncRedisModel.client.del(key) { |resp| }
        end
        blk.call(true)
      end
      
      def load(&blk)
        return nil unless id
        self.class.all_index.includes?(id) do |resp|
          raise(AsyncRedisModel::RecordNotFoundError, id.to_s) unless resp
          AsyncRedisModel.client.mget(*attribute_keys) do |resp|
            if resp && resp.is_a?(Array)
              @attributes ||= {}
              @orig_attributes ||= {}
              attribute_names.each_with_index do |name, i|
                @attributes[name.to_sym] = decoded_value(resp[i])
                begin
                  @orig_attributes[name.to_sym] = @attributes[name.to_sym].dup
                rescue TypeError => e
                  @orig_attributes[name.to_sym] = @attributes[name.to_sym]
                end
              end
              blk.call(true)
            else
              blk.call(false)
            end
          end
        end
      end
      
      protected
      
      def kv_pairs_for_mset
        self.class.defined_attributes.collect do |name, opts|
          val = self.attributes[name.to_sym]
          [key_for_attribute(name), encoded_value(val)]
        end.flatten
      end
    end # InstanceMethods
  end # Persistence
end # AsyncRedisModel