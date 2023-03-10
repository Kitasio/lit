defmodule LitcoversWeb.PromptLive.FormComponent do
  use LitcoversWeb, :live_component

  alias Litcovers.Metadata

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage prompt records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="prompt-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :name}} type="text" label="Name" />
        <.input
          field={{f, :realm}}
          type="select"
          label="Realm"
          prompt="Choose a value"
          options={Ecto.Enum.values(Litcovers.Metadata.Prompt, :realm)}
        />
        <.input
          field={{f, :sentiment}}
          type="select"
          label="Sentiment"
          prompt="Choose a value"
          options={Ecto.Enum.values(Litcovers.Metadata.Prompt, :sentiment)}
        />
        <.input
          field={{f, :type}}
          type="select"
          label="Type"
          prompt="Choose a value"
          options={Ecto.Enum.values(Litcovers.Metadata.Prompt, :type)}
        />
        <.input field={{f, :style_prompt}} type="text" label="Style prompt" />
        <.input field={{f, :image_url}} type="text" label="Image url" />
        <.input field={{f, :secondary_url}} type="text" label="Secondary url" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Prompt</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{prompt: prompt} = assigns, socket) do
    changeset = Metadata.change_prompt(prompt)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"prompt" => prompt_params}, socket) do
    changeset =
      socket.assigns.prompt
      |> Metadata.change_prompt(prompt_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"prompt" => prompt_params}, socket) do
    save_prompt(socket, socket.assigns.action, prompt_params)
  end

  defp save_prompt(socket, :edit, prompt_params) do
    case Metadata.update_prompt(socket.assigns.prompt, prompt_params) do
      {:ok, _prompt} ->
        {:noreply,
         socket
         |> put_flash(:info, "Prompt updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_prompt(socket, :new, prompt_params) do
    case Metadata.create_prompt(prompt_params) do
      {:ok, _prompt} ->
        {:noreply,
         socket
         |> put_flash(:info, "Prompt created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
