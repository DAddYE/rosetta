require 'bundler/gem_tasks'
require 'bundler/setup'
require 'rake/testtask'

desc 'Start an interactive repl'
task :console do
  ARGV.clear
  require 'pry'
  require 'rosetta'
  Pry.start
end

desc 'Generates the parser'
task :parser do |a, b|
  sh 'racc -E -v lib/rosetta/grammar.y -o lib/rosetta/parser.rb'
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test_*.rb']
end

task default: :test
