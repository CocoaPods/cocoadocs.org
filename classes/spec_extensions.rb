require 'redcarpet'
require 'uri'

module Pod
  class Specification
    def escaped_name
      URI.escape(name)
    end

    def or_is_github?
      homepage.include?("github.com") || (source[:git] && source[:git].include?("github.com"))
    end

    def or_github_url
      return homepage if homepage.include?("github.com")
      return source[:git] if source[:git] && source[:git].include?("github.com")
    end

    def or_podspec_url
      "https://github.com/CocoaPods/Specs/blob/master/Specs/#{ escaped_name }/#{ version }/#{ escaped_name }.podspec.json"
    end

    def or_cocoadocs_url
      "https://s3.amazonaws.com/cocoadocs.org/docsets/#{ escaped_name }/#{ version }"
    end

    def or_git_ref
      source[:tag] || source[:commit] || source[:branch] || 'master'
    end

    def or_user
      return nil unless self.or_is_github?
      or_github_url.split("/")[-2]
    end

    def or_repo
      return nil unless self.or_is_github?
      or_github_url.split("/")[-1].gsub(".git", "")
    end

    def or_github_search_context
      return "" unless self.or_is_github?
      " repo:" + or_user + "/" + or_repo
    end

    def or_github_search_context_method
      "https://github.com/search?q={{methodSelector}}++extension%3Am" + or_github_search_context + "&type=Code&ref=searchresults"
    end

    def or_github_search_context_class
      "https://github.com/search?q={{object/nameOfClass}}++extension%3Am" + or_github_search_context + "&type=Code&ref=searchresults"
    end

    def or_extensionless_homepage
      return nil unless homepage
      homepage.sub('http://', '').sub('https://', '').sub('www.', '').split("/")[0]
    end

    def or_contributors_to_spec
      return authors if authors.is_a? String
      return authors.listify if authors.is_a? Array
      return authors.keys.listify if authors.is_a? Hash
    end

    def or_license
      return license if license.is_a? String
      return license[:type] if license.is_a? Hash
      "Unknown License"
    end

    def or_podfile_string
      if (version.to_s.match(/[^.0-9]/))
        "pod '#{name}', '#{version}'"
      else
        minor_version = version.to_s.split('.').slice(0, 2).join(".")
        "pod '#{name}', '~> #{minor_version}'"
      end
    end

    def or_license_name_and_url
      if license.is_a? Hash
        license = self.license[:type].downcase

        if license.scan(/mit/).count > 0
          return { license: "MIT", url: "http://opensource.org/licenses/MIT" }

        elsif license =~ /apache ?(license, version )?2(\.0)?/i
          return { license: "Apache 2", url: "https://www.apache.org/licenses/LICENSE-2.0.html" }

        elsif license.scan(/bsd 3/).count > 0
          return { license: "BSD 3.0", url: "http://opensource.org/licenses/BSD-3-Clause" }
        elsif license.scan(/new bsd/).count > 0
          return { license: "BSD 3.0", url: "http://opensource.org/licenses/BSD-3-Clause" }
        elsif license.scan(/bsd 2/).count > 0
          return { license: "BSD 2.0", url: "http://opensource.org/licenses/BSD-2-Clause" }
        elsif license.scan(/2-clause bsd/).count > 0
          return { license: "BSD 2.0", url: "http://opensource.org/licenses/BSD-2-Clause" }
        elsif license.scan(/bsd/).count > 0
          return { license: "BSD", url: "https://en.wikipedia.org/wiki/BSD_licenses" }

        elsif license.scan(/creative commons/).count > 0
          return { license: "CC", url: "https://creativecommons.org/licenses/" }
        elsif license.scan(/commercial/).count > 0
          return { license: "Commercial", url: homepage }
        elsif license.scan(/netbsd/).count > 0
          return { license: "NetBSD", url: "http://www.netbsd.org/about/redistribution.html" }

        elsif license.scan(/(Affero.*GPL|AGPL) v3/).count > 0
          return { license: "AGPL 3", url: "http://opensource.org/licenses/AGPL-3.0" }
        elsif license.scan(/lgpl v3/).count > 0
          return { license: "LGPL 3", url: "http://opensource.org/licenses/lgpl-3.0.html" }
        elsif license.scan(/gpl v3/).count > 0
          return { license: "GPL 3", url: "http://opensource.org/licenses/gpl-3.0.html" }

        elsif license.scan(/boost/).count > 0
          return { license: "Boost", url: "http://www.boost.org/users/license.html" }
        elsif license.scan(/eclipse/).count > 0
          return { license: "eclipse", url: "http://www.eclipse.org/legal/epl-v10.html" }
        elsif license.scan(/zlib/).count > 0
          return { license: "zlib", url: "http://opensource.org/licenses/Zlib" }
        elsif license.scan(/wtf/).count > 0
          return { license: "WTFPL", url: "http://www.wtfpl.net" }
        elsif license.scan(/eclipse/).count > 0
          return { license: "Eclipse", url: "http://www.eclipse.org/legal/epl-v10.html" }
        end
      end

      { license: "Custom", url: homepage }
    end

    def or_has_social_media_url?
      social_media_url != nil
    end

    def or_has_twitter_url?
      self.or_has_social_media_url? && social_media_url.include?("twitter.com")
    end

    def or_repo_url
    end

    def or_can_show_code?
    end

    def or_twitter_handle
      social_media_url.split(".com/")[-1]
    end

    def or_social_media_title
      if social_media_url.include?("twitter.com")
        return "@" + social_media_url.split(".com/")[-1]
      end

      if social_media_url.include?("facebook.com")
        return "FB: " + social_media_url.split(".com/")[-1]
      end

      if social_media_url.include?("github.com")
        return "GH: " + social_media_url.split(".com/")[-1]
      end

      if social_media_url.include?("linkedin.com")
        return "LI: " + social_media_url.split(".com/")[-1]
      end

      social_media_url.sub("https://","").sub("http://","").split("/")[0]
    end

    def or_spec_is_deprecated?
      deprecated || deprecated_in_favor_of
    end

    def or_summary_html
      original_text = description || summary
      renderer = Redcarpet::Render::HTML.new(filter_html: true, safe_links_only: true)
      markdown = Redcarpet::Markdown.new(renderer)
      markdown.render(original_text.strip_heredoc.strip).strip
    end
 end
end
