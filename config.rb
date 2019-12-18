#!/usr/bin/ruby

require 'yaml'
data = YAML.load_file('internal_users.yml')

data['admin']['hash'] = ARGV[0]
data['kibanaserver']['hash'] = ARGV[1]

File.open("internal_users.yml", 'w') { |f| YAML.dump(data, f) }
