module JekyllRefer
  class Util
    attr_accessor :config
    def initialize(site)
      @site = site
      @site.config["refer"] ||= {
        "key" => "ref"
      }
      @config = @site.config["refer"]
    end

    def all_pages
      return @site.collection_names.inject(@site.pages){|_pages,col_name|
        _pages = _pages + @site.collections[col_name].docs
      }
    end
  end
end
