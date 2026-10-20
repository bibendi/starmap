module McpHelpers
  def mcp_request(method, params = {}, token: nil)
    headers = {"CONTENT_TYPE" => "application/json"}
    headers["AUTHORIZATION"] = "Bearer #{token}" if token
    post "/mcp", params: {jsonrpc: "2.0", id: 1, method: method, params: params}.to_json, headers: headers
    response.parsed_body
  end

  def mcp_call(name, arguments = {}, token: nil)
    mcp_request("tools/call", {name: name, arguments: arguments}, token: token).fetch("result")
  end

  def mcp_payload(result)
    expect(response).to have_http_status(:ok)
    expect(result.fetch("isError")).to be false
    JSON.parse(result.fetch("content").first.fetch("text"))
  end
end
