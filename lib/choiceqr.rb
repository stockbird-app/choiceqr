require_relative "choiceqr/version"
require_relative "choiceqr/errors"
require_relative "choiceqr/configuration"
require_relative "choiceqr/key_transformer"
require_relative "choiceqr/resource"
require_relative "choiceqr/resources/base"
require_relative "choiceqr/resources/place"
require_relative "choiceqr/resources/section_info"
require_relative "choiceqr/resources/sections"
require_relative "choiceqr/resources/categories"
require_relative "choiceqr/resources/dishes"
require_relative "choiceqr/resources/dish_options"
require_relative "choiceqr/resources/dish_labels"
require_relative "choiceqr/resources/pack"
require_relative "choiceqr/resources/cutlery"
require_relative "choiceqr/resources/full_menu"
require_relative "choiceqr/resources/areas"
require_relative "choiceqr/resources/location_points"
require_relative "choiceqr/resources/orders"
require_relative "choiceqr/resources/bookings"
require_relative "choiceqr/resources/feedbacks"
require_relative "choiceqr/client"

module ChoiceQR
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset!
      @configuration = Configuration.new
    end
  end
end
