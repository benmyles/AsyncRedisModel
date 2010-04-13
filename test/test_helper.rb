require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/async_redis_model'

class Person < AsyncRedisModel::Base
  define_attribute :name
  define_attribute :age
  define_attribute :zip
  
  define_index_on  :zip
end