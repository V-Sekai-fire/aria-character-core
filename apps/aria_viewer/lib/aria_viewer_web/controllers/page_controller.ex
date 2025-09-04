defmodule AriaViewerWeb.PageController do
  use AriaViewerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
