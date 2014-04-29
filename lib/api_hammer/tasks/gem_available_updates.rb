namespace :gem do
  desc 'informs you of available gem updates, newer than the gem versions in your Gemfile or Gemfile.lock'
  task :available_updates do
    require 'bundler'
    Bundler.definition.dependencies.each do |dependency|
      lock_version = Bundler.definition.specs.detect { |spec| spec.name == dependency.name }.version
      remote_specs = Gem::SpecFetcher.fetcher.detect(:latest) { |name_tuple| name_tuple.name == dependency.name }
      remote_specs.reject! do |(remote_spec, source)|
        remote_spec.version <= lock_version
      end
      if remote_specs.any?
        puts "LOCAL #{dependency.name} #{dependency.requirement} (locked at #{lock_version})"
        remote_specs.each do |(remote_spec, source)|
          puts "\tREMOTE AVAILABLE: #{remote_spec.name} #{remote_spec.version} #{remote_spec.platform}"
        end
      end
    end
  end
end
