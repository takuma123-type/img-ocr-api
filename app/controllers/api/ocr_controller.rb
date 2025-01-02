class Api::OcrController < Api::BaseController
  before_action :validate_params, only: :process_image

  def process_image
    begin
      # ファイルの保存
      file = params[:file]
      saved_path = save_uploaded_file(file)

      usecase = Api::OcrUsecase.new(
        input: Api::OcrUsecase::Input.new(
          image_path: saved_path
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
    unless params[:file].present?
      render json: { error: 'File is required' }, status: :bad_request
      return
    end

    unless params[:file].is_a?(ActionDispatch::Http::UploadedFile)
      render json: { error: 'Invalid file format' }, status: :bad_request
    end
  end

  def save_uploaded_file(file)
    directory = Rails.root.join('public', 'uploads')
    FileUtils.mkdir_p(directory) unless Dir.exist?(directory)

    path = directory.join(file.original_filename)
    File.open(path, 'wb') { |f| f.write(file.read) }
    Rails.logger.info "File saved at: #{path}"
    path.to_s
  end
end
