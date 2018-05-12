Gem::Specification.new do |s|
  s.name          = 'logstash-codec-json_gz'
  s.version       = '1.0.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = "Reads gzip encoded JSON formatted content, creating one event per element in a JSON array or JSON line."
  s.description   = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.homepage      = 'https://github.com/dterziev/logstash-codec-json_gz'
  s.authors       = ['Dimo Terziev']
  s.email         = 'dimo.terziev@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "codec" }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api',  ">= 1.60", "<= 2.99"
  s.add_development_dependency 'logstash-devutils'
end
