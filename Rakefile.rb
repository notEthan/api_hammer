require 'rake/testtask'
Rake::TestTask.new do |t|
  t.name = 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
task 'default' => 'test'

begin
  require 'gig'
  gig_loaded = true
rescue LoadError
end

if gig_loaded
  ignore_files = %w(
    .github/**/*
    .gitignore
    Gemfile*
    Rakefile.rb
    test/**/*
  ).map { |glob| Dir.glob(glob, File::FNM_DOTMATCH) }.inject([], &:|)
  Gig.make_task(gemspec_filename: 'api_hammer.gemspec', ignore_files: ignore_files)
end
