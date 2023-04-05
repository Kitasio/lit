defmodule LitcoversWeb.AdminLive.Feedback do
  use LitcoversWeb, :live_view
  alias Litcovers.Accounts

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    feedbacks = Accounts.list_feedbacks()

    {:ok, assign(socket, locale: locale, feedbacks: feedbacks)}
  end
end