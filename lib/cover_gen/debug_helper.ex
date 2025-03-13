defmodule CoverGen.DebugHelper do
  require Logger

  @doc """
  Logs detailed information about a request to help with debugging
  """
  def log_request(conn, params) do
    Logger.info("==== DEBUG REQUEST INFO ====")
    Logger.info("Request path: #{conn.request_path}")
    Logger.info("Request method: #{conn.method}")
    Logger.info("Request params: #{inspect(params, pretty: true)}")
    
    # Log headers that might be useful
    headers_to_log = ["content-type", "accept", "authorization"]
    headers = Enum.filter(conn.req_headers, fn {key, _} -> key in headers_to_log end)
    Logger.info("Request headers: #{inspect(headers)}")
    
    # Return the conn unchanged
    conn
  end

  @doc """
  Logs detailed information about a model selection
  """
  def log_model_selection(model_name, provider) do
    Logger.info("==== MODEL SELECTION ====")
    Logger.info("Selected model: #{model_name}")
    Logger.info("Provider: #{inspect(provider)}")
  end
end
