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

      it 'should provide a html equivilent of the complex description' do
        @spec.description = 'Hello.\n\n# Heading\n\nBunch of things\n\n* List of something.'
        @spec.or_summary_html.should == '<p>Hello.\n\n# Heading\n\nBunch of things\n\n* List of something.</p>'
      end

      it 'doesnt add inline HTML in HTML equivilent of the summary' do
        @spec.summary = 'Hello, there\n\n<img src="thing">\n\nOK'
        @spec.or_summary_html.should == '<p>Hello, there\n\n\n\nOK</p>'
      end

      it 'should provide a HTML equivilent of the summary, with links' do
        @spec.summary = 'Hello, there [world](#ok).'
        @spec.or_summary_html.should == '<p>Hello, there <a href="#ok">world</a>.</p>'
      end

      it 'should provide a HTML equivilent of the summary' do
        @spec.summary = 'Simple.'
        @spec.or_summary_html.should == '<p>Simple.</p>'
      end

    end
  end
end
