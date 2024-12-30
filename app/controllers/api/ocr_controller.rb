class Api::OcrController < Api::BaseController
  before_action :validate_params, only: :process_image

  def process_image
    begin
      usecase = Api::OcrUsecase.new(
        input: Api::OcrUsecase::Input.new(
          image_path: params[:image_path]
        )
      )
      @output = usecase.fetch
      render json: @output.response
    rescue => e
      Rails.logger.error "Error processing image: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def validate_params
    unless params[:image_path].present?
      render json: { error: 'image_path is required' }, status: :bad_request
      return
    end

    unless File.exist?(params[:image_path])
      render json: { error: "File not found at #{params[:image_path]}" }, status: :bad_request
    end
  end
end
