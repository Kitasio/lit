defmodule CoverGen.Worker.Corrector do
  alias Litcovers.Metadata
  alias CoverGen.OAIChat
  alias CoverGen.Worker.StateHolder
  use GenServer, restart: :transient
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    image = Keyword.get(args, :image)
    message = Keyword.get(args, :message, "")
    stage = Keyword.get(args, :stage, :oai_request)
    params = Keyword.get(args, :params, %{})
    state_holder_name = Keyword.get(args, :state_holder_name)

    # lock_user(image.user_id)

    state = %{
      image: image,
      message: message,
      stage: stage,
      state_holder_name: state_holder_name,
      params: params,
      image_list: []
    }

    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    current_state = StateHolder.get(state.state_holder_name)
    send(self(), current_state.stage)
    {:noreply, state}
  end

  def handle_info(:oai_request, state) do
    # arrange the chat
    messages = arrange_chat(state.image.chats, state)

    # insert user chat to database
    Metadata.create_chat(state.image, List.last(messages))

    # send the chat to OAI
    {:ok, res} = OAIChat.send(messages, System.get_env("OAI_TOKEN"))

    # save the response to database
    Metadata.create_chat(state.image, res)

    # Updating the state
    # new_state = %{state | params: params, stage: :sd_request}
    # StateHolder.set(state.state_holder_name, new_state)
    #
    # {:noreply, new_state, {:continue, :run}}
    {:stop, :normal, state}
  end

  def arrange_chat([], state),
    do: [%{role: "user", content: "#{state.image.final_prompt} 

  #{state.message}"}]

  def arrange_chat(chats, state) when is_list(chats) do
    old_messages =
      Enum.map(chats, fn chat ->
        %{
          role: chat.role,
          content: chat.content
        }
      end)

    old_messages ++ [%{role: "user", content: state.message}]
  end
end
