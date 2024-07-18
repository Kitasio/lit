defmodule LitcoversWeb.DocsLive.Index do
  use LitcoversWeb, :live_view

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)

    {:ok, assign(socket, locale: locale)}
  end
end
