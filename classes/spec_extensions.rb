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

      def or_has_social_media_url?
        self.social_media_url != nil
      end

      def or_has_twitter_url?
        self.social_media_url.include?("twitter.com")
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
