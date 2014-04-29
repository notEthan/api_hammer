require 'rake/testtask'
Rake::TestTask.new do |t|
  t.name = 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
task 'default' => 'test'

require 'yard'
YARD::Rake::YardocTask.new do |t|
end
