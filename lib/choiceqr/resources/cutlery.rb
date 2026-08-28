module ChoiceQR
  module Resources
    # Cutlery modal configuration (single settings object, no id).
    #
    #   client.cutlery.get
    #   client.cutlery.update(show: true, required_cutlery: false)
    class Cutlery < Base
      def get(language: nil)
        fetch_one("menu/#{lang(language)}/cutlery")
      end

      # PUT — returns true on success.
      def update(language: nil, **attributes)
        mutate(:put, "menu/#{lang(language)}/cutlery", body: attributes)
      end
    end
  end
end
