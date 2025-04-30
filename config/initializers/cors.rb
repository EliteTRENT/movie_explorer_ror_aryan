Rails.logger.info "Loading CORS middleware"
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
Rails.logger.info "CORS middleware loaded successfully"