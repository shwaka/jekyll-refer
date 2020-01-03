require 'jekyll-refer/util'

module JekyllRefer
  class CopiedPage < Jekyll::Page
    def initialize(page, layout)
      if not page.is_a?(Jekyll::Page)
        raise "invalid arg"
      end
      @site = page.site
      @base = @site.source
      @dir  = page.dir
      @name = page.name
      @path = page.path

      process(@name)
      # read_yaml(PathManager.join(@base, @dir), @name)
      self.content = page.content
      self.data = page.data.clone
      self.data["layout"] = layout

      data.default_proc = proc do |_, key|
        @site.frontmatter_defaults.find(relative_path, type, key)
      end

      Jekyll::Hooks.trigger :pages, :post_init, self
    end
  end

  def render_page(page)
    if not page.is_a?(::Jekyll::Page)
      raise "invalid arg"
    end
    site = page.site
    payload = site.site_payload
    output = Jekyll::Renderer.new(site, page, payload).run
    return output
  end

  def get_page(site, page_hash)
    if page_hash.is_a?(Jekyll::Page)
      return page_hash
    elsif page_hash.is_a?(Hash)
      path = page_hash["path"]
      util = ::JekyllRefer::Util.new(site)
      page = util.all_pages.find do |_page|
        _page.path == path
      end
      return page
    else
      raise "invalid arg"
    end
  end
  module_function :render_page, :get_page
end

module Jekyll
  module IncludeContentFilter
    def include_content(page_hash, layout=:default)
      site = @context.registers[:site]
      page = ::JekyllRefer::get_page(site, page_hash)
      if layout == :default
        util = ::JekyllRefer::Util.new(site)
        layout_name = util.config["include_layout"]
      elsif layout.is_a?(String) or layout.nil?
        layout_name = layout
      else
        raise "invalid layout"
      end
      copied_page = ::JekyllRefer::CopiedPage.new(page, layout_name)
      output = ::JekyllRefer::render_page(copied_page)
      return output
    end
  end
end

Liquid::Template.register_filter(Jekyll::IncludeContentFilter)
