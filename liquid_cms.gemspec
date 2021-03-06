# -*- encoding: utf-8 -*-
require File.expand_path("../lib/liquid_cms/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "liquid_cms"
  s.version     = Cms::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Andrew Kaspick', 'Redline Software Inc.']
  s.email       = ['andrew@redlinesoftware.com']
  s.homepage    = "http://rubygems.org/gems/liquid_cms"
  s.summary     = "A context aware Rails CMS engine using the Liquid template library."
  s.description = <<-TXT
  A context aware Rails CMS engine using the Liquid template library.
  Use the 0.3.x version for Rails 3 compatibility and the 0.2.x version for Rails 2 compatibility.
  TXT

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "liquid_cms"

  s.add_dependency 'bundler', ">= 1.0.0"
  s.add_dependency 'rails', '~> 3.0.0'
  s.add_dependency 'paperclip', '~> 2.3.1'
  #s.add_dependency 'vestal_versions', '~> 1.2.1'
  s.add_dependency 'simple_form', '~> 1.5.2'
  s.add_dependency 'rubyzip', '~> 0.9.1'
  s.add_dependency 'will_paginate', '~> 2.3.12'
  s.add_dependency 'formatize'

  s.add_development_dependency 'sqlite3-ruby'
  s.add_development_dependency 'factory_girl', "~> 1.3.0"
  s.add_development_dependency 'shoulda', "~> 2.10.3"
  s.add_development_dependency 'mocha'

  test_files = `git ls-files test/`.split("\n")
  all_files  = `git ls-files`.split("\n")

  s.files        = all_files - test_files
  s.test_files   = test_files
  s.executables  = all_files.map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
