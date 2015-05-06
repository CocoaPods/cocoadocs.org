require 'tempfile'
require File.expand_path('../spec_helper', __FILE__)
require '_utils'
require 'spec_extensions'
require 'readme_manipulator'
require "nokogiri"

describe 'with CDZUIKitAutoLayoutDebugging' do
  def manipulator_for pod
    tmp_readme = "/tmp/#{pod}.html"
    `cp spec/fixtures/readme/#{pod}.html #{tmp_readme}`
    
    spec = Pod::Specification.from_file "spec/fixtures/podspecs/#{pod}.podspec.json"
    ReadmeManipulator.new( :readme_path => tmp_readme, :spec => spec )
  end
  
  before do
    @manipulator = manipulator_for "CDZUIKitAutoLayoutDebugging"
  end

  def contain(substring)
    lambda { |obj| obj.include?(substring) }
  end

  it 'should remove all badges ' do
    @manipulator.run_for_cocoadocs
    readme_html = File.read @manipulator.readme_path
    
    readme_html.should.not contain('shields.io')
  end

  it 'should remove the main header ' do
    @manipulator.run_for_cocoadocs
    readme_html = File.read @manipulator.readme_path
    
    readme_html.should.not contain('CDZUIKitAutoLayoutDebugging</h1>')
  end

end

