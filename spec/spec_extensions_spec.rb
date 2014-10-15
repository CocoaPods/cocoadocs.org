require File.expand_path('../spec_helper', __FILE__)
require 'spec_extensions'

module Pod
  describe Specification do
    describe 'or extensions' do
      before do
        @spec = Pod::Spec.new do |spec|
          spec.name = 'QueryKit'
          spec.version = '0.8.3'
          spec.homepage = 'http://querykit.org/'
          spec.license = { :type => 'BSD', :file => 'LICENSE' }
          spec.authors = { 'Kyle Fuller' => 'inbox@kylefuller.co.uk' }
        end
      end

      it 'should provide the correct podspec URL on GitHub for the master repo' do
        @spec.or_podspec_url.should == 'https://github.com/CocoaPods/Specs/blob/master/Specs/QueryKit/0.8.3/QueryKit.podspec.json'
      end

      it 'should provide the license' do
        @spec.or_license.should == 'BSD'
      end

      it 'should provide an extensionless homepage' do
        @spec.or_extensionless_homepage.should == 'querykit.org'
      end

      describe 'license name and url extension' do
        it 'should detect the BSD license' do
          @spec.or_license_name_and_url.should == { :license => 'BSD', :url => 'https://en.wikipedia.org/wiki/BSD_licenses'}
        end

        it 'should detect the MIT license' do
          @spec.stubs(:license).returns({ :type => 'MIT' })
          @spec.or_license_name_and_url.should == { :license => 'MIT', :url => 'http://opensource.org/licenses/MIT'}
        end

        it 'should detect the WTFPL license' do
          @spec.stubs(:license).returns({ :type => 'WTFPL' })
          @spec.or_license_name_and_url.should == { :license => 'WTFPL', :url => 'http://www.wtfpl.net'}
        end
      end
    end
  end
end

