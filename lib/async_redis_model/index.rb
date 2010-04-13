require 'digest/sha1'

module AsyncRedisModel
  class Index
    class MissingOptionError < RuntimeError; end
    
    attr_accessor :class_name, :key
  
    def self.build_key(class_name, *args)
      ["AsyncRedisModel",class_name,args].join(":")
    end
    
    def self.encoded_value(val)
      AsyncRedisModel::Base.encoded_value(val)
    end
  
    def initialize(opts)
      @class_name = opts[:class_name] || raise(MissingOptionError, ":class_name required")
      if opts[:key]
        @key = opts[:key]
      elsif opts[:name] && opts[:value]
        @key = self.class.build_key(
                    opts[:class_name],
                    opts[:name], 
                    Digest::SHA1.hexdigest(self.class.encoded_value(opts[:value])))
      else
        raise(MissingOptionError, ":key or :name AND :value required")
      end
    end
    
    def add(record_id, &blk)
      AsyncRedisModel.client.sadd(self.key, record_id) do |resp|
        blk.call(resp)
      end
    end
    
    def rem(record_id, &blk)
      AsyncRedisModel.client.srem(self.key, record_id) do |resp|
        blk.call(resp)
      end
    end
    
    def includes?(record_id, &blk)
      AsyncRedisModel.client.sismember(self.key, record_id) do |resp|
        blk.call(resp == 1)
      end
    end
    
    alias :include? :includes?
    
    def members(&blk)
      AsyncRedisModel.client.smembers(self.key) do |resp|
        blk.call(resp || [])
      end
    end
    
  end
end