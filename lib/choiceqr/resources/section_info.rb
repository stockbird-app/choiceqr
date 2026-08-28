module ChoiceQR
  module Resources
    # The customizable message shown at the top of a menu section.
    #
    #   client.section_info.get(section_id)   # => Resource
    class SectionInfo < Base
      def get(section_id, language: nil)
        fetch_one("menu/#{lang(language)}/section-info/#{section_id}")
      end
    end
  end
end
