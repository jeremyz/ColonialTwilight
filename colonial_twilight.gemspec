#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

$:.push File.expand_path('../lib', __FILE__)
require 'colonial_twilight'

Gem::Specification.new do |s|
    s.name      = 'ColonialTwilight'
    s.version   = ColonialTwilight::VERSION
    s.licenses  = ['MIT']
    s.authors   = ['Jérémy Zurcher']
    s.email     = ['jeremy@asynk.ch']
    s.homepage  = 'https://asynk.ch'
    s.summary   = %q{FLN bot for GMT's Colonial Twilight.}
    s.description = %q{This is a colorful FLN bot for GMT's COIN series' Colonial Twilight.}

    s.files       = Dir['lib/**/*.rb']
    s.executables = 'ColonialTwilight.rb'
    s.add_development_dependency 'rspec'
    s.add_development_dependency 'simplecov'
end
