# Takes a readme path and 

class ReadmeManipulator
  include HashInit
  attr_accessor :spec, :readme_path

  def run_for_cocoadocs
    return unless @spec.or_is_github?
    return unless File.exist? @readme_path
    
    fix_relative_links_in_gfm
    remove_known_badges
    remove_named_header
    fix_header_anchors
    remove_other_managers
  end
  
  def run_for_jazzy
    return unless @spec.or_is_github?
    return unless File.exist? @readme_path
    
    fix_relative_links_in_gfm('article.main-content .section')
    remove_known_badges
    remove_named_header
    fix_header_anchors
    remove_other_managers
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

    "https://raw.github.com/#{@spec.or_user}/#{@spec.or_repo}/#{@spec.or_git_ref}/#{CGI.escape link_string}"
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

    # Nokogiri counts whitespace as a text node, so remote all of them for this case
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
                      'https://badge.waffle.io']
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

  def remove_other_managers

  end

end