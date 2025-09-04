defmodule AriaViewerWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use PhoenixHTMLHelpers

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "invalid-feedback"
      )
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, _opts}) do
    # When using gettext, we typically pass the errors to Gettext.
    # Since we don't have Gettext configured, we'll just return the message.
    msg
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
  def translate_errors(errors, field) when is_map(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
