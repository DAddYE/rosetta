def sh(*cmds)
  cmd = "bundle exec #{cmds.map(&:to_s) * ' '}"
  puts "$ #{cmd}"
  system cmd
end

guard :shell do
  watch('lib/rosetta/grammar.y'){ sh 'rake parser' }
  watch(%r'example/.*\.ros'){ |m| system 'clear'; sh 'ruby example/run.rb', m[0] }
end

group :ros do
  guard :shell do
    watch(/.*\.go\.ros$/) do |m|
      go_file = m[0].sub(/\.ros$/, '')
      sh './bin/ros -t go -c', m[0], '>', go_file
      system 'go build %s' % go_file
    end
  end
end

guard :minitest do
  watch(%r'^test/(.*)\/?test_(.*)\.rb$')
  watch(%r'^lib/rosetta/(.*/)?([^/]+)\.rb$') { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r'^test/test_helper\.rb$')          { 'test' }

  # Custom stuff
  watch(%r'^lib/rosetta/nodes.rb') { 'test/test_parser.rb' }
end
