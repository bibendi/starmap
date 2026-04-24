# frozen_string_literal: true

class McpBaseTool < MCP::Tool
  class Error < StandardError; end
  NotFoundError = Class.new(Error)
  ForbiddenError = Class.new(Error)

  def self.call(**kwargs)
    execute(**kwargs)
  rescue NotFoundError, ForbiddenError => e
    error_response(e.message)
  end

  class << self
    private

    def execute(**)
      raise NotImplementedError
    end

    def authorize(user, record, query = :show)
      policy = Pundit.policy(user, record)
      return if policy.public_send("#{query}?")

      display_name = record.respond_to?(:name) ? record.name : record.id
      raise ForbiddenError, "You do not have permission to view #{record.class.name.downcase} '#{display_name}'"
    end

    def not_found!(message)
      raise NotFoundError, message
    end

    def text_response(text)
      MCP::Tool::Response.new([{type: "text", text:}])
    end

    def error_response(message)
      MCP::Tool::Response.new([{type: "text", text: message}], error: true)
    end
  end
end
