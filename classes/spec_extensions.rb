module Pod
    class Specification

      def or_is_github?
        self.homepage.include?("github.com") || (self.source[:git] && self.source[:git].include?("github.com"))
      end

      def or_git_ref
        self.source[:tag] || self.source[:commit] || self.source[:branch] || 'master'
      end

      def or_user
        return nil unless self.or_is_github?
        self.homepage.split("/")[-2]
      end

      def or_repo
        return nil unless self.or_is_github?
        self.homepage.split("/")[-1]
      end

      def or_extensionless_homepage
        return nil unless self.homepage
        self.homepage.sub('http://', '').sub('https://', '').sub('www.', '').split("/")[0]
      end

      def or_contributors_to_spec
        return self.authors if self.authors.is_a? String
        return self.authors.listify if self.authors.is_a? Array
        return self.authors.keys.listify if self.authors.is_a? Hash
      end

      def or_license
        return self.license if self.license.is_a? String
        return self.license[:type] if self.license.is_a? Hash
        return "Unknown License"
      end

      def or_license_name_and_url
        if self.license.is_a? Hash
          license = self.license[:type].downcase

          if license.scan(/mit/).count > 0
            return { :license => "MIT", :url => "http://opensource.org/licenses/MIT" }

          elsif license.scan(/apache license, version 2.0/).count > 0
            return { :license => "Apache 2", :url => "https://www.apache.org/licenses/LICENSE-2.0.html" }
          elsif license.scan(/apache 2.0/).count > 0
            return { :license => "Apache 2", :url => "https://www.apache.org/licenses/LICENSE-2.0.html" }
          elsif license.scan(/apache2/).count > 0
            return { :license => "Apache 2", :url => "https://www.apache.org/licenses/LICENSE-2.0.html" }

          elsif license.scan(/bsd 3/).count > 0
            return { :license => "BSD 3.0", :url => "http://opensource.org/licenses/BSD-3-Clause" }
          elsif license.scan(/new bsd/).count > 0
            return { :license => "BSD 3.0", :url => "http://opensource.org/licenses/BSD-3-Clause" }
          elsif license.scan(/bsd 2/).count > 0
            return { :license => "BSD 2.0", :url => "http://opensource.org/licenses/BSD-2-Clause" }
          elsif license.scan(/2-clause bsd/).count > 0
            return { :license => "BSD 2.0", :url => "http://opensource.org/licenses/BSD-2-Clause" }
          elsif license.scan(/bsd/).count > 0
            return { :license => "BSD", :url => "https://en.wikipedia.org/wiki/BSD_licenses" }

          elsif license.scan(/creative commons/).count > 0
            return { :license => "CC", :url => "https://creativecommons.org/licenses/" }
          elsif license.scan(/commercial/).count > 0
            return { :license => "Commercial", :url => self.homepage }
          elsif license.scan(/netbsd/).count > 0
            return { :license => "NetBSD", :url => "http://www.netbsd.org/about/redistribution.html" }

          elsif license.scan(/lgpl v3/).count > 0
            return { :license => "LGPL 3", :url => "http://opensource.org/licenses/lgpl-3.0.html" }
          elsif license.scan(/gpl v3/).count > 0
            return { :license => "GPL 3", :url => "http://opensource.org/licenses/gpl-3.0.html" }
          elsif license.scan(/gpl v3/).count > 0
            return { :license => "GPL 3", :url => "http://www.netbsd.org/about/redistribution.html" }

          elsif license.scan(/boost/).count > 0
            return { :license => "Boost", :url => "http://www.boost.org/users/license.html" }
          elsif license.scan(/eclipse/).count > 0
            return { :license => "eclipse", :url => "http://www.eclipse.org/legal/epl-v10.html" }
          elsif license.scan(/zlib/).count > 0
            return { :license => "zlib", :url => "http://opensource.org/licenses/Zlib" }
          elsif license.scan(/wtf/).count > 0
            return { :license => "WTFPL", :url => "http://www.wtfpl.net" }
          elsif license.scan(/eclipse/).count > 0
            return { :license => "eclipse", :url => "http://www.eclipse.org/legal/epl-v10.html" }
          end
        end

        return { :license => "Custom License", :url => self.homepage }
      end

      def or_has_social_media_url?
        self.social_media_url != nil
      end

      def or_has_twitter_url?
        self.social_media_url.include?("twitter.com")
      end

      def or_repo_url

      end

      def or_can_show_code?

      end

      def or_twitter_handle
        return self.social_media_url.split(".com/")[-1]
      end

      def or_social_media_title
        if self.social_media_url.include?("twitter.com")
          return "@" + self.social_media_url.split(".com/")[-1]
        end

        if self.social_media_url.include?("facebook.com")
          return "FB: " + self.social_media_url.split(".com/")[-1]
        end

        if self.social_media_url.include?("github.com")
          return "GH: " + self.social_media_url.split(".com/")[-1]
        end

        self.social_media_url
      end

      def or_spec_is_deprecated?
        self.deprecated || self.deprecated_in_favor_of
      end
   end
end
