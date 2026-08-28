module ChoiceQR
  class Configuration
    attr_accessor :timeout, :open_timeout, :logger, :default_language

    API_BASE_URL = "https://open-api.choiceqr.com/".freeze

    def initialize
      @timeout          = 30
      @open_timeout     = 5
      @logger           = nil
      @default_language = "en"
    end
  end
end
