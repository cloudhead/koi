require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "koi"
    gem.summary = %Q{minimal task management for hackers}
    gem.description = %Q{minimalist console-based task management for hackers}
    gem.email = "self@cloudhead.net"
    gem.homepage = "http://github.com/cloudhead/koi"
    gem.authors = ["cloudhead"]
    gem.add_development_dependency "rspec"
    gem.add_dependency "mutter", ">= 0.4"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ['--color', '--format=specdoc']
end

task :spec => :check_dependencies

task :default => :spec

