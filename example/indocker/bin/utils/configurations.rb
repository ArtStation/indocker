def list_configurations(configurations_dir)
  Dir[File.join(configurations_dir, '**/*.rb')].map {|c| c.split('/').last.gsub('.rb', '')}
end