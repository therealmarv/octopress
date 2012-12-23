# Title: Include Code Tag for Jekyll
# Author: Brandon Mathis http://brandonmathis.com
# Description: Import files on your filesystem into any blog post as embedded code snippets with syntax highlighting and a download link.
# Configuration: You can set default import path in _config.yml (defaults to code_dir: downloads/code)
#
# Syntax {% include_code path/to/file %}
#
# Example 1:
# {% include_code javascripts/test.js %}
#
# This will import test.js from source/downloads/code/javascripts/test.js
# and output the contents in a syntax highlighted code block inside a figure,
# with a figtitle listing the file name and download link
#
# Example 2:
# You can also include an optional title for the <figtitle>
#
# {% include_code javascripts/test.js Example 2 %}
#
# will output a figtitle with the title: Example 2 (test.js)
#

require './plugins/pygments_code'
require 'pathname'

module Jekyll

  class IncludeCodeTag < Liquid::Tag
    include HighlightCode
    def initialize(tag_name, markup, tokens)
      @file = nil
      @title = nil
      @title_old = nil

      options    = parse_markup(markup)
      @lang      = options[:lang]
      @title     = options[:title]
      @lineos    = options[:lineos]
      @marks     = options[:marks]
      @url       = options[:url]
      @link_text = options[:link_text]
      @start     = options[:start]
      @end       = options[:end]
      markup     = clean_markup(markup)

      if markup.strip =~ /(^\S*\.\S+) *(.+)?/i
        @file = $1
        @title ||= $2
      elsif markup.strip =~ /(.*?)(\S*\.\S+)\Z/i # Title before file is deprecated in 2.1
        @title_old = $1
        @file = $2
      end
      super
    end

    def render(context)
      code_dir = (context.registers[:site].config['code_dir'].sub(/^\//,'') || 'downloads/code')
      code_path = (Pathname.new(context.registers[:site].source) + code_dir).expand_path
      file = code_path + @file

      unless @title_old.nil?
        @title ||= @title_old
        puts "### ------------ WARNING ------------ ###"
        puts "This include_code syntax is deprecated "
        puts "Correct syntax: path/to/file.ext [title]"
        puts "Update include for #{file}"
        puts "### --------------------------------- ###"
      end
      
      if File.symlink?(code_path)
        puts "Code directory '#{code_path}' cannot be a symlink"
        return "Code directory '#{code_path}' cannot be a symlink"
      end

      unless file.file?
        puts "File #{file} could not be found"
        return "File #{file} could not be found"
      end

      Dir.chdir(code_path) do
        code = file.read
        length = code.lines.count
        @end   ||= length
        @start ||= 1
        return "#{file} is #{length} lines long, cannot begin at line #{@start}" if @start > length
        return "#{file} is #{length} lines long, cannot read beyond line #{@end}" if @end > length
        if @start > 1 or @end < length
          code = code.split(/\n/).slice(@start -1, @end + 1 - @start).join("\n")
        end
        @lang = file.extname.sub('.','') unless @lang
        title = @title ? "#{@title} (#{file.basename})" : file.basename
        url = "/#{code_dir}/#{@file}"
        highlight(code, @lang, {title: title, url: url, link_text: @link_text || 'view raw', start: @start, marks: @marks, linenos: @linenos })
      end
    end
  end

end

Liquid::Template.register_tag('include_code', Jekyll::IncludeCodeTag)
