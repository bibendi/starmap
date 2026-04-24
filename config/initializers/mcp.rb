# frozen_string_literal: true

MCP.configure do |config|
  config.exception_reporter = lambda do |exception, context|
    Rails.logger.error("[MCP] #{exception.class}: #{exception.message}")
    Rails.logger.debug { "[MCP] Context: #{context.inspect}" }
  end

  config.around_request = lambda do |_data, &block|
    block.call
  end
end
