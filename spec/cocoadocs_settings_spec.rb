require 'tempfile'
require File.expand_path('../spec_helper', __FILE__)
require '_utils'
require 'spec_extensions'
require 'cocoadocs_settings'

describe 'Getting settings' do

  it 'with .cocoadocs file it should include their options' do
    path = "spec/fixtures/settings"
    settings = CocoaDocsSettings.settings_at_location path
    settings["darker-color"].should.be.equal '#b2c6b9;';
  end

  it 'without cocoadocs file it should have defaults' do
    settings = CocoaDocsSettings.settings_at_location ""
    settings["darker-color"].should.be.equal '#C6B7B2'
  end
end
