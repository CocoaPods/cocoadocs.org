module Pod
    class Specification

      def or_is_github?
        self.homepage.include? "github.com"
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

   end
end
