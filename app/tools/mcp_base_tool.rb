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

    def authorize(identity, record, query = :show)
      policy = resolve_policy(identity, record)
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

    def resolve_policy(identity, record)
      policy = if identity.is_a?(ApiClient)
        Pundit.policy(identity, [:api_client, record])
      else
        Pundit.policy(identity, record)
      end

      raise Pundit::NotDefinedError, "unable to find policy for `#{record.class.name}`" unless policy

      policy
    end
  end
end
