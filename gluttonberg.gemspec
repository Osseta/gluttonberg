# Generated by jeweler
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gluttonberg}
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Crowther","Abdul Rauf", "Luke Sutton", "Yuri Tomanek"]
  s.date = %q{2011-03-30}
  s.email = %q{office@freerangefuture.com}
  s.files = [
    
  ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Gluttonberg – An Open Source Content Management System being developed by Freerange Future}
  s.test_files = [
     "spec"
  ]

  s.add_dependency "authlogic", '2.1.6'
  s.add_dependency "will_paginate" , '3.0.pre2'
  s.add_dependency "rubyzip", '0.9.4'
  s.add_dependency "acts_as_tree", '0.1.1'
  s.add_dependency "acts_as_list", '0.1.2' 
  s.add_dependency "acts_as_versioned", '0.6.0'
  s.add_dependency "acts-as-taggable-on", '2.0.6'  
  s.add_dependency "delayed_job", '2.1.4' 
  s.add_dependency 'jeditable-rails', '0.1.1'
  s.add_dependency 'cancan', '1.6.4'
  s.add_dependency 'active_link_to', '0.0.7'
  s.add_dependency 'texticle' , '1.0.4.20101004123327'
  s.add_development_dependency "rspec-rails", "2.0.1"

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
