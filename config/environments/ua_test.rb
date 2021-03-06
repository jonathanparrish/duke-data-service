Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  if Rails.version > '5.0.0'
    config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  else
    config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?
  end
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true
  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
  config.force_ssl = true
  # config.lograge.enabled = true
  # config.lograge.formatter = Lograge::Formatters::Json.new
  # config.lograge.custom_options = lambda do |event|
  #   {
  #     request_id: event.payload[:request_id],
  #     transaction_id: event.transaction_id,
  #     request_time: event.time,
  #     request_end: event.end,
  #     user_agent: event.payload[:user_agent],
  #     #remote_ip: event.payload[:remote_ip],
  #     grape_controller: event.payload[:params]["controller"]
  #   }
  # end
end
