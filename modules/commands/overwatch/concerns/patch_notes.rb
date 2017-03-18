require 'nokogiri'
require 'open-uri'
require 'reverse_markdown'
require 'uri'


module Overwatch
  module PatchNotes
    def get_page(url)
      contents = open(url).read
      Nokogiri::HTML(contents)
    end

    def get_raw_ow_patchnotes
      notes = get_page("https://playoverwatch.com/en-us/game/patch-notes/pc/")
      notes.css('.patch-notes-body').first
    end

    def get_raw_ptr_patchnotes
      notes = get_page("https://blizztrack.com/overwatch_ptr/patch_notes/latest")
      notes.css('.patchnoteswrap')
    end

    def get_ow_pns
      ReverseMarkdown.convert get_raw_ow_patchnotes.to_s
    end

    def get_ptr_pns
      ReverseMarkdown.convert get_raw_ptr_patchnotes.to_s
    end
  end
end
