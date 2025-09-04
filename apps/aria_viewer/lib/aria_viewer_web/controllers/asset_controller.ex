defmodule AriaViewerWeb.AssetController do
  use AriaViewerWeb, :controller

  def js(conn, _params) do
    js_path = Path.join(:code.priv_dir(:aria_viewer), "static/js/app.js")

    case File.read(js_path) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("application/javascript")
        |> send_resp(200, content)

      {:error, _reason} ->
        conn
        |> put_status(404)
        |> text("JavaScript file not found")
    end
  end
end
