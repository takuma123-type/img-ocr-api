class Api::Usecase < ApplicationUsecase
  class Input < ApplicationUsecase::Input
  end

  class Output < ApplicationUsecase::Output
  end

  class Error < StandardError
    include ActiveModel::Model
  end
end