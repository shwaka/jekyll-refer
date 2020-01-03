# coding: utf-8
require 'pathname'
require 'jekyll-refer/util'

module JekyllRefer
  def copy(page_or_doc, layout)
    if page_or_doc.is_a?(Jekyll::Page)
      return CopiedPage.new(page_or_doc, layout)
    elsif page_or_doc.is_a?(Jekyll::Document)
      return PageFromDocument.new(page_or_doc, layout)
    else
      raise "invalid arg: #{page_or_doc.class}"
    end
  end
  module_function :copy

  class CopiedPage < Jekyll::Page
    def initialize(page, layout)
      if not page.is_a?(Jekyll::Page)
        raise "invalid arg: #{page.class}"
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

  class PageFromDocument < Jekyll::Page
    # Jekyll::Document を継承してつくっても上手くいかなかった．
    # より正確に言うと，include そのものは上手くいったが，
    # その副作用として include 元の document がおかしくなった．
    # Document の @path を(symlink を使うなどして)別の場所に退避すれば
    # 一応動作したけど…
    def initialize(doc, layout)
      if not doc.is_a?(Jekyll::Document)
        raise "invalid arg: #{page.class}"
      end
      @site = doc.site
      @base = @site.source
      @path = doc.path
      pathname = Pathname(@path)
      @dir = pathname.dirname.to_s
      @name = pathname.basename.to_s

      process(@name)
      # read_yaml(PathManager.join(@base, @dir), @name)
      self.content = doc.content
      self.data = doc.data.clone
      self.data["layout"] = layout

      data.default_proc = proc do |_, key|
        @site.frontmatter_defaults.find(relative_path, type, key)
      end

      Jekyll::Hooks.trigger :pages, :post_init, self
    end
  end

  def render_page(page)
    if not page.is_a?(::Jekyll::Page)
      raise "invalid arg: #{page.class}"
    end
    site = page.site
    payload = site.site_payload
    output = Jekyll::Renderer.new(site, page, payload).run
    return output
  end

  def get_page(site, page_hash)
    if page_hash.is_a?(::Jekyll::Page)
      return page_hash
    elsif page_hash.is_a?(Hash) or page_hash.is_a?(::Jekyll::Drops::DocumentDrop)
      # post だと page_hash に DocumentDrop が入ってる
      site_source = Pathname.new(site.source)
      path = site_source / page_hash["path"]
      util = ::JekyllRefer::Util.new(site)
      page = util.all_pages.find do |_page|
        path == site_source / _page.path
      end
      if page.nil?
        raise "this cant happen"
      end
      return page
    else
      raise "invalid arg: #{page_hash.class}"
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
      copied_page = ::JekyllRefer::copy(page, layout_name)
      output = ::JekyllRefer::render_page(copied_page)
      return output
    end
  end
end

Liquid::Template.register_filter(Jekyll::IncludeContentFilter)
