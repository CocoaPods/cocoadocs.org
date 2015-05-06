require 'tempfile'
require File.expand_path('../spec_helper', __FILE__)
require '_utils'
require 'spec_extensions'
require 'readme_manipulator'
require "nokogiri"

def contain(substring)
  lambda { |obj| obj.include?(substring) }
end

def rendered_readme_for pod
  tmp_readme = "/tmp/#{pod}.html"
  `cp spec/fixtures/readme/#{pod}.html #{tmp_readme}`
  
  spec = Pod::Specification.from_file "spec/fixtures/podspecs/#{pod}.podspec.json"
  manipulator = ReadmeManipulator.new( :readme_path => tmp_readme, :spec => spec )
  manipulator.run_for_cocoadocs
  File.read manipulator.readme_path
end

describe 'with CDZUIKitAutoLayoutDebugging' do
  
  before do
    @readme = rendered_readme_for "CDZUIKitAutoLayoutDebugging"
  end

  it 'should remove all badges ' do    
    @readme.should.not contain('shields.io')
  end

  it 'should remove the main header ' do
    @readme.should.not contain('CDZUIKitAutoLayoutDebugging</h1>')
  end
  
  it 'should not feature carthage' do
    @readme.should.not contain('dependency to your Cartfile')
  end
  
  it 'should not feature cocoapods' do
    @readme.should.not contain("pod 'CDZUIKitAutoLayoutDebugging'")
  end
  
end

describe 'with Cent' do
  it 'should not feature carthage' do
    rendered_readme_for("Cent").should.not contain('If unfamiliar with Carthage')
  end
end

describe 'with HanekeSwift' do
  it 'should not mention carthage' do    
     rendered_readme_for("HanekeSwift").should.not contain('Using Carthage')
  end
  
  it 'should not feature CocoaPods' do
    rendered_readme_for("HanekeSwift").should.not contain("pod 'Hanake")
  end
end

describe 'with AlamoFire' do
  it 'should not mention carthage' do
    rendered_readme_for("AlamoFire").should.not contain('install Carthage')
  end
  
  it 'should not feature CocoaPods' do
    rendered_readme_for("AlamoFire").should.not contain("pod 'Alamo")
  end
end

describe 'with SwityJSON' do
  it 'should not mention carthage' do
    rendered_readme_for("SwiftyJSON").should.not contain('You can use Carthage')
  end
  
  it 'should not feature CocoaPods' do
    rendered_readme_for("SwiftyJSON").should.not contain("pod 'Swifty")
  end
end

describe 'with Expecta' do
  
  it 'should not feature CocoaPods' do
    rendered_readme_for("Cent").should.not contain("pod 'Expecta")
  end
  
  it 'should mention carthage' do
    readme_html = rendered_readme_for("Expecta")
    readme_html.should contain('using Carthage')
  end
  
  it 'should not link to the carthage repo' do
    readme_html = rendered_readme_for("Expecta")
    readme_html.should.not contain('github.com/Carthage/Carthage')
  end
  
  it 'should remove larger carthage section' do
    readme_html = rendered_readme_for("Expecta")
    readme_html.should.not contain('carthage update')
  end
end
