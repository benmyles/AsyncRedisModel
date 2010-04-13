$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

gem "activemodel", "= 3.0.0.beta2"
gem "activesupport", "= 3.0.0.beta2"

require "active_model"
require "active_support/all"


require "#{File.dirname(__FILE__)}/../vendor/em-redis"

module AsyncRedisModel
  VERSION = '0.0.1'
  
  def self.client
    #@client ||= EventMachine::Protocols::Redis.connect
    Thread.current[:async_redis_model] ||= {}
    Thread.current[:async_redis_model][:client] ||= EventMachine::Protocols::Redis.connect
  end
end

require "#{File.dirname(__FILE__)}/async_redis_model/base"
