#!/usr/bin/ruby

require 'yaml'
obj = YAML.load_file('internal_users.yml')

bcrypt_hash='$2y$12$shEKzuVfogdZFbbraSqhwOOh96hfxe1NzLQbpmHJvgDUeRfRrkf3a' 
obj['kibanaserver'] = {"hash" => ARGV[0]}
obj['admin'] = {"hash" => ARGV[1]}

puts YAML.dump(obj)
