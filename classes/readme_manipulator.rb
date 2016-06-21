# Takes a readme path and

class ReadmeManipulator
  include HashInit
  attr_accessor :spec, :readme_path

  def run_for_cocoadocs
    return unless @spec.or_is_github?
    return unless File.exist? @readme_path

    make_dupe
    fix_relative_links_in_gfm
    remove_known_badges
    remove_named_header
    fix_header_anchors
    remove_dependency_manager_cues
  end

  def run_for_jazzy
    return unless @spec.or_is_github?
    return unless File.exist? @readme_path

    fix_relative_links_in_gfm('article.main-content .section')
    remove_known_badges
    remove_named_header
    fix_header_anchors
    remove_dependency_manager_cues('article.main-content .section')
  end

  def make_dupe
    FileUtils.cp @readme_path, @readme_path.sub(".html", "_original.html")
  end

  def fix_relative_link(link_string)
    if link_string.start_with? "#"
      return link_string
    end
    if link_string.start_with? "http"
      return link_string
    end
    if link_string.start_with? "https"
      return link_string
    end
    if link_string.include? "@"
      return link_string
    end

    # Turn forward slahes(%2F) back into forward slashes
    link_path = CGI.escape(link_string).gsub('%2F', '/')
    "https://raw.github.com/#{@spec.or_user}/#{@spec.or_repo}/#{@spec.or_git_ref}/#{link_path}"
  end

  def fix_relative_links_in_gfm(parent_selector = nil)
    vputs "Fixing relative URLs in github flavoured markdown"

    doc = Nokogiri::HTML(File.read @readme_path)
    main = parent_selector ? doc.css(parent_selector).first : doc
    main.css("a").each do |link|
      if link.attributes["href"]
        link.attributes["href"].value = fix_relative_link link.attributes["href"].value
      end
    end

    main.css("img").each do |img|
      if img.attributes["src"]
        img.attributes["src"].value = fix_relative_link img.attributes["src"].value
      end
    end

    `rm \"#{@readme_path}\"`
    File.open(@readme_path, 'w') { |f| f.write(doc) }
  end

  # Don't have a redundant header under the site's provided one
  def remove_named_header
    doc = Nokogiri::HTML(File.read @readme_path)

    # Nokogiri counts whitespace as a text node, so remove all of them for this case
    real_elements = doc.xpath('/html/body/child::node()').select do |node|
      node.type != Nokogiri::XML::Node::TEXT_NODE || node.content =~ /\S/
    end

    header_anchor = real_elements[0]

    # Is it an empty paragraph (because we removed all badges?
    if header_anchor.name == "p" && header_anchor.text.strip == ""
      header_anchor.remove
      header_anchor = real_elements[1]
    end

    header_anchor.remove if header_anchor.text.strip == @spec.name

    `rm \"#{@readme_path}\"`
    File.open(@readme_path, 'w') { |f| f.write(doc) }
  end

  def remove_known_badges
    vputs "Fixing Travis links in markdown"

    doc = Nokogiri::HTML(File.read @readme_path)

    doc.css('a[href^="https://travis-ci.org"]').each do |link|
      link.remove if link.inner_html.include? ".svg"
      link.remove if link.inner_html.include? ".png?branch"
    end

    urls_to_delete = ['http://cocoapod-badges.herokuapp',
                      'https://cocoapod-badges.herokuapp',
                      'https://img.shields.io',
                      'http://img.shields.io',
                      'https://reposs.herokuapp.com',
                      'https://secure.travis-ci.org',
                      'https://kiwiirc.com',
                      'https://badges.gitter.im',
                      'https://coveralls.io',
                      'https://landscape.io',
                      'https://badge.waffle.io',
                      'https://codecov.io/',
                      'https://versioneye.com/']
    urls_to_delete.each do |selector|
      doc.css('img[data-canonical-src^="' + selector + '"]').each do |image|
        image.parent.remove
      end
    end

    `rm \"#{@readme_path}\"`
    File.open(@readme_path, 'w') { |f| f.write(doc) }
  end

  def fix_header_anchors
    vputs "Fixing header anchor names"

    return unless @spec.or_is_github?
    return unless File.exist? @readme_path

    doc = Nokogiri::HTML(File.read @readme_path)

    nodes = doc.css('h1, h2, h3')
    nodes.each do |node|
      href = node.css('a').first
      if href && href.attributes["name"]
        href.attributes["name"].value = href.attributes["name"].value.gsub(/user-content-/, "")
      end
    end

    `rm \"#{@readme_path}\"`
    File.open(@readme_path, 'w') { |f| f.write(doc) }
  end

  def remove_dependency_manager_cues(parent_selector = nil)
    doc = Nokogiri::HTML(File.read @readme_path)
    main = parent_selector ? doc.css(parent_selector).first : doc.css("body")

    # replace all clickable Carthage links with just the text
    doc.css('a[href^="https://github.com/Carthage/Carthage"]').each do |link|
      link.replace(Nokogiri::XML::Text.new(link.text, doc))
    end

    # replace all clickable CP links with just the text
    doc.css('a[href^="https://cocoapods.org"]').each do |link|
      link.replace(Nokogiri::XML::Text.new(link.text, doc))
    end

    # replace sections beginning with a header
    main = remove_dependency_manager_section main, "carthage"
    main = remove_dependency_manager_section main, "cocoapods"

    # look for just a paragraph then a pre with 'github "' or 'pod "
    main = remove_two_linked_paragraphs main, "carthage", 'github "'
    main = remove_two_linked_paragraphs main, "cocoapods", 'pod "'

    # Look for an empty installation section and remove the 'installation' h2
    install = doc.at('h2:contains("Install")')
    if install
      install_index = main.children.find_index install
      first_sibling = nil

      # Get first non-empty value
      (install_index + 1..main.children.length).each do |index|
        child = main.children[index]
        next if child.text.strip.empty?

        first_sibling = child
        break
      end

      install.remove if first_sibling.name == "h2"
    end

    File.open(@readme_path, 'w') { |f| f.write(doc) }
  end

  def remove_dependency_manager_section main_element, name
    in_section = false
    main_element.children.each do |child|
      next if child.type == Nokogiri::XML::Node::TEXT_NODE

      # This turns it on, but won't turn itself off
      in_section = true if child.name.start_with?("h") && child.text.downcase.include?(name)

      # This turns it off when we reach a new header
      in_section = false if child.name.start_with?("h") && !child.text.downcase.include?(name)

      child.remove if in_section
    end

    main_element
  end

  def remove_two_linked_paragraphs main_element, before, after

    paragraph_node = nil
    nodes = main_element.children
    nodes.each do |child|
      next if child.type == Nokogiri::XML::Node::TEXT_NODE

      paragraph_node = child if child.name == "p" && child.text.downcase.include?(before)
      pre_node = child if child.name == "pre" && child.text.downcase.include?(after)

      if paragraph_node && pre_node
        index_difference = nodes.index(pre_node) - nodes.index(paragraph_node)

        # We have to include the skipped text node, thus 2
        if index_difference == 2
          paragraph_node.remove
          pre_node.remove
          break
        end
      end
    end

    main_element
  end

end
