require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/async_redis_model'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'async_redis_model' do
  self.developer 'Ben Myles', 'ben.myles@gmail.com'
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [['activemodel','= 3.0.0.beta2'],
                             ['activesupport','= 3.0.0.beta2']]
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
