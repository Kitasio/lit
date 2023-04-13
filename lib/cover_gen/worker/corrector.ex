defmodule CoverGen.Worker.Corrector do
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
    message = state.image.final_prompt <> "\n#{state.message}"
    Logger.info("message: #{message}")
    res = OAIChat.send(message, System.get_env("OAI_TOKEN"))
    Logger.info("OAI res: #{inspect(res)}")

    # Updating the state
    # new_state = %{state | params: params, stage: :sd_request}
    # StateHolder.set(state.state_holder_name, new_state)
    #
    # {:noreply, new_state, {:continue, :run}}
    {:stop, :normal, state}
  end
end
