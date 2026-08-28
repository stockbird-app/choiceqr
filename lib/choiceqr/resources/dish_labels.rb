module ChoiceQR
  module Resources
    # Personal (custom) dish labels, e.g. "Chef's pick".
    #
    #   client.dish_labels.list   # => Array<Resource>
    class DishLabels < Base
      def list(language: nil)
        fetch_list("menu/#{lang(language)}/dish-labels/list")
      end
    end
  end
end
