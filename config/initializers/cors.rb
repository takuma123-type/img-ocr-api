Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:8000' # フロントエンドのオリジン

    resource '*',
      headers: :any,                   # 任意のヘッダーを許可
      methods: [:get, :post, :options], # 必要な HTTP メソッドを許可
      credentials: false               # Cookie 認証が不要なら false
  end
end
