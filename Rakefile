#!/usr/bin/env ruby

require_relative 'lib/post_install'

# Import all tasks in the lib/tasks directory
Dir.glob(File.join(File.dirname(__FILE__), 'lib', 'tasks', '*.rake')).each do |task|
  import task
end

# Set the default task to 'rake_install:clean'
task :default => 'rake_install:install'
