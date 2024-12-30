class ApplicationUsecase
  class Input
    include ActiveModel::Model
  end

  class Output
    include ActiveModel::Model
  end

  attr_reader :input

  def initialize(input:)
    @input = input

    if Rails.env.development?
      Rails.logger.info(self.class) { "input: '#{input.to_json}'" }
    end
  end
end