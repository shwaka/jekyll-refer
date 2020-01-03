# coding: utf-8
module Jekyll
  module ReferFilters
    def refer(input, noerror=false, *args)
      # ページが見つからないときは nil を返す
      site = @context.registers[:site]
      config_refer = site.config["refer"]
      refer_key = config_refer["key"]
      options = alist_to_hash(args)
      current_page = @context.registers[:page]
      # page の デフォルト値
      if config_refer.key?("default_to_page")
        config_refer["default_to_page"].each do |key|
          if current_page.key?(key) and not options.key?(key)
            options[key] = current_page[key]
          end
        end
      end
      pages = site.collection_names.inject(site.pages){|_pages,col_name|
        _pages = _pages + site.collections[col_name].docs
      }
      # if default_ref then
      #   page = find_page(pages, refer_key, input, options) ||
      #          find_page(pages, refer_key, default_ref, options)
      # else
      #   page = find_page(pages, refer_key, input, options)
      # end
      page = find_page(pages, refer_key, input, options, noerror)
      # if page.nil? and default_ref
      #   # default_ref でも nil を返すかもしれないので，下の if とは統合できない
      #   page = find_page(pages, refer_key, default_ref, options)
      #   current_page["refer_default"] = true
      # else
      #   current_page["refer_default"] = false
      # end
      if page.nil?
        return nil
        # path = current_page["path"]
        # raise "no page found for #{refer_key}=#{input} with options #{options} during processing #{path}"
      end
      return page
    end
    def refer_url(input)
      # input must be a page or nil
      if input.nil?
        return nil
      end
      return input["url"]
    end
    def refer_link(input, text=nil, prefix="")
      # input must be a page or nil
      if input.nil?
        return nil
      end
      page = input
      url = refer_url(page)
      # Jekyll::Filters::URLFilters.absolute_url ってそのまま呼び出せるの？extend?
      # url = absolute_url(refer_url(page))
      site = @context.registers[:site]
      baseurl = site.config["baseurl"]
      url = baseurl + refer_url(page)
      if text
        link_text = text
      elsif page["title"]
        link_text = prefix + page["title"]
      else
        url
      end
      # text = text || page["title"] || url
      return "<a href=\"#{url}\">#{link_text}</a>"
    end

    private

    def alist_to_hash(alist)
      # alist = association list (from lisp)
      if alist.length % 2 != 0
        raise "alist.length must be even!"
      end
      hash_result = {}
      (0...(alist.length / 2)).each do |i|
        hash_result[alist[2*i]] = alist[2*i+1]
      end
      return hash_result
    end

    def find_page(pages, refer_key, ref, options, noerror)
      pages_filtered = pages
                         .select{|page| options.keys.all?{|key| page.data[key] == options[key]}}
                         .select{|page| page.data[refer_key] == ref }
      if pages_filtered.length == 0
        if noerror
          return nil
        end
        current_page_path = @context.registers[:page]["path"]
        raise "page not found:\nref=#{ref} with options #{options} in #{current_page_path}"
      elsif pages_filtered.length == 1
        return pages_filtered[0]
      else
        page_urls = pages_filtered.map do |page|
          page.url
        end.to_a
        raise "too many pages matched:\nref: #{ref}\npages: #{page_urls}"
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::ReferFilters)
