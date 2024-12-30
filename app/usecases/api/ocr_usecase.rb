module Api
  class OcrUsecase < Api::Usecase
    class Input < Api::Usecase::Input
      attr_accessor :image_path

      def initialize(image_path:)
        @image_path = image_path
      end
    end

    class Output < Api::Usecase::Output
      attr_accessor :response

      def initialize(response:)
        @response = response
      end
    end

    def initialize(input:)
      @input = input
    end

    def fetch
      Rails.logger.info "Processing OCR for image: #{@input.image_path}"

      # Step 1: OCRでテキスト抽出
      extracted_text = extract_text_from_image(@input.image_path)
      if extracted_text.nil? || extracted_text.empty?
        Rails.logger.error "OCR Extraction Failed: No text extracted"
        raise "画像からテキストを抽出できませんでした"
      end

      Rails.logger.info "OCR Extracted Text: #{extracted_text}"

      # Step 2: OpenAIでJSON整形
      openai = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"))
      response = openai.chat(
        parameters: {
          model: "gpt-4",
          messages: [
            {
              role: "system",
              content: <<~PROMPT
                以下の日本語テキストを解析し、次の情報をJSON形式で返してください：
                - 店名 (store_name)
                - 登録番号 (registration_number)
                - 電話番号 (phone_number)
                - 住所 (address)
                - 日付 (date)
                - 金額 (amount)
              PROMPT
            },
            {
              role: "user",
              content: extracted_text
            }
          ],
          temperature: 0,
          max_tokens: 1000
        }
      )

      result = response.dig('choices', 0, 'message', 'content')
      Rails.logger.info "OpenAI Raw Response: #{result}"

      # レスポンスをパース
      begin
        if result.strip.start_with?('{') && result.strip.end_with?('}')
          parsed_result = JSON.parse(result)
          Rails.logger.info "Parsed JSON Response: #{parsed_result}"
          Output.new(response: sanitize_response(parsed_result))
        else
          Rails.logger.error "OpenAI Response is not JSON: #{result}"
          Output.new(response: default_response)
        end
      rescue JSON::ParserError => e
        Rails.logger.error "JSON Parse Error: #{e.message} - Raw Content: #{result}"
        Output.new(response: default_response)
      end
    end

    private

    # OCR処理
    def extract_text_from_image(image_path)
      begin
        text = RTesseract.new(image_path, lang: 'jpn').to_s
        Rails.logger.info "Extracted Text from Image: #{text}"
        text
      rescue => e
        Rails.logger.error "OCR Error: #{e.message}"
        nil
      end
    end

    # 不明なフィールドを補完する
    def sanitize_response(parsed_result)
      {
        "store_name" => parsed_result["store_name"] || "不明",
        "registration_number" => parsed_result["registration_number"] || "不明",
        "phone_number" => parsed_result["phone_number"] || "不明",
        "address" => parsed_result["address"] || "不明",
        "date" => parsed_result["date"] || "不明",
        "amount" => parsed_result["amount"] || "不明"
      }
    end

    # デフォルトレスポンス
    def default_response
      {
        "store_name" => "不明",
        "registration_number" => "不明",
        "phone_number" => "不明",
        "address" => "不明",
        "date" => "不明",
        "amount" => "不明"
      }
    end
  end
end
