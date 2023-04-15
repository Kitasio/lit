defmodule LitcoversWeb.ImageLive.New do
  alias Litcovers.Accounts.Feedback
  alias Litcovers.Accounts
  alias CoverGen.Replicate
  alias Litcovers.Metadata.Prompt
  alias Litcovers.Payments.Yookassa
  alias Litcovers.Payments
  alias Litcovers.Accounts
  alias Litcovers.Media
  alias Litcovers.Media.Image
  alias Litcovers.Metadata
  require Elixir.Logger
  import LitcoversWeb.ImageLive.Index
  alias Phoenix.LiveView.JS

  use LitcoversWeb, :live_view

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    if connected?(socket), do: CoverGen.Worker.Creator.subscribe(socket.assigns.current_user.id)
    Gettext.put_locale(locale)

    check_new_payments(socket, self())

    socket =
      if socket.assigns.current_user.relaxed_mode do
        relaxed_mode_releaser(socket.assigns.current_user, self())

        push_event(socket, "init-relaxed-mode-timer", %{
          id: "relaxed-timer-user-#{socket.assigns.current_user.id}",
          relaxed_till: relaxed_mode_till(socket.assigns.current_user)
        })
      else
        socket
      end

    style_prompts = list_style_prompts()
    stage = get_stage(0)

    {:ok,
     assign(socket,
       changeset: Media.change_image(%Image{}),
       locale: locale,
       lit_ai: false,
       aspect_ratio: "cover",
       style_prompts: style_prompts,
       style_prompt: nil,
       prompt_id: nil,
       stage: stage,
       realms: realms(),
       realm: :fantasy,
       types: types(),
       type: :object,
       sentiments: sentiments(),
       sentiment: :positive,
       gender: :female,
       placeholder: random_placeholder(locale, true),
       width: 512,
       height: 768,
       image: %Image{},
       gen_error: nil,
       is_generating: socket.assigns.current_user.is_generating,
       has_images: has_images?(socket.assigns.current_user),
       has_new_images: has_new_images?(socket.assigns.current_user),
       models: Replicate.Model.list_all(),
       selected_model: Replicate.Model.list_all() |> List.first(),
       current_tut: nil,
       user_tuts: Metadata.list_user_tutorials(socket.assigns.current_user)
     )}
  end

  defp tutorials do
    [
      %{
        title: "create",
        banner_url: "https://ik.imagekit.io/soulgenesis/create_tut.jpg",
        header: gettext("Create"),
        text: [
          gettext(
            "We're here! At the first step, you will be able to enter a description of the desired image or an annotation of the book in text, then select the aspect ratio and finally determine the most appropriate styles."
          ),
          gettext(
            "Toggle switch LIT.AI disables our idea generator, giving you the opportunity to accurately describe the desired image"
          )
        ],
        button: gettext("Begin!")
      }
    ]
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :feedback, _params) do
    socket
    |> assign(form: Accounts.change_feedback(%Feedback{}))
  end

  defp apply_action(socket, :index, _params) do
    next = next_tut(socket, tutorials())

    if connected?(socket) and next != nil do
      Metadata.create_tutotial(socket.assigns.current_user, %{title: next.title})
    end

    assign(socket, current_tut: next)
  end

  # TODO: refactor it
  defp apply_action(socket, :redo, params) do
    message = Map.get(params, "message")
    image_id = Map.get(params, "image_id")
    image = Media.get_image_preload_all!(image_id)

    unless socket.assigns.current_user.is_generating or socket.assigns.current_user.relaxed_mode or
             image.ideas == [] do
      prompt =
        if image.prompt != nil do
          case Metadata.get_prompt(image.prompt.id) do
            nil ->
              list_style_prompts() |> List.first()

            prompt ->
              prompt
          end
        else
          list_style_prompts() |> List.first()
        end

      style_prompts = Metadata.list_all_where(prompt.realm, prompt.sentiment, prompt.type)

      image_params = %{
        description: image.description,
        width: image.width,
        height: image.height,
        character_gender: image.character_gender,
        final_prompt: image.final_prompt
      }

      {:ok, new_image} =
        Media.create_image(socket.assigns.current_user, image.prompt, image_params)

      for chat <- image.chats do
        Metadata.create_chat(new_image, %{content: chat.content, role: chat.role})
      end

      CoverGen.create_new(
        image: new_image,
        stage: :oai_chat,
        message: message
      )

      for i <- image.ideas do
        Media.create_idea(new_image, %{idea: i.idea})
      end

      socket = push_event(socket, "update-description-input", %{description: image.description})

      socket
      |> assign(
        image: new_image,
        stage: get_stage(3),
        prompt: prompt,
        gender: image.character_gender,
        style_prompt: prompt.style_prompt,
        style_prompts: style_prompts,
        prompt_id: prompt.id,
        realm: prompt.realm,
        sentiment: prompt.sentiment,
        type: prompt.type,
        aspect_ratio: get_aspect_ratio({image.width, image.height}),
        is_generating: true
      )
    else
      redirect(socket, to: ~p"/#{socket.assigns.locale}/images/new")
    end
  end

  @impl true
  def handle_info({:gen_timeout, _image_id}, socket) do
    socket =
      assign(socket,
        gen_error: gettext("Timeout"),
        is_generating: false
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:oai_failed, _image_id}, socket) do
    socket = assign(socket, gen_error: gettext("Something went wrong"), is_generating: false)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:sd_failed, _image_id}, socket) do
    socket = assign(socket, gen_error: gettext("Something went wrong"), is_generating: false)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:unknown_error, _image_id}, socket) do
    socket = assign(socket, gen_error: gettext("Something went wrong"), is_generating: false)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:gen_complete, image_id}, socket) do
    image = Media.get_image_preload!(image_id)

    socket = push_event(socket, "update-description-input", %{description: image.description})

    {:noreply,
     socket
     |> assign(image: image, is_generating: false, has_images: true, has_new_images: true)}
  end

  @impl true
  def handle_info({:update_user, user}, socket) do
    socket = push_event(socket, "update-litcoins", %{id: "litcoins-of-user-#{user.id}"})
    {:noreply, assign(socket, current_user: user)}
  end

  @impl true
  def handle_info({:relaxed_mode, image_id}, socket) do
    image = Media.get_image_preload!(image_id)
    {:ok, user} = Accounts.relax_user_for(socket.assigns.current_user, 1)
    relaxed_mode_releaser(user, self())

    socket =
      push_event(socket, "init-relaxed-mode-timer", %{
        id: "relaxed-timer-user-#{user.id}",
        relaxed_till: relaxed_mode_till(user)
      })

    socket =
      unless Metadata.has_tutorial?(socket.assigns.current_user, "feedback") do
        Metadata.create_tutotial(socket.assigns.current_user, %{title: "feedback"})
        redirect(socket, to: "/#{socket.assigns.locale}/images/new/feedback")
      else
        socket
      end

    {:noreply,
     socket
     |> assign(
       image: image,
       current_user: user,
       is_generating: false,
       has_images: true,
       has_new_images: true
     )}
  end

  def handle_info({:end_relax, user}, socket) do
    params = %{relaxed_mode: false, recent_generations: 0}
    {:ok, user} = Accounts.update_relaxed_mode(user, params)
    {:noreply, assign(socket, current_user: user)}
  end

  # unlocks image spending 1 litcoin to current user
  @impl true
  def handle_event("unlock", %{"image_id" => image_id}, socket) do
    litcoins = socket.assigns.current_user.litcoins

    if litcoins > 0 do
      image = Media.get_image!(image_id)
      {:ok, image} = Media.unlock_image(image)
      {:ok, user} = Accounts.remove_litcoins(socket.assigns.current_user, 1)
      socket = push_event(socket, "update-litcoins", %{id: "litcoins"})
      socket = assign(socket, image: image, current_user: user)
      {:noreply, redirect(socket, to: "/#{socket.assigns.locale}/images/#{image.id}/edit")}
    else
      {:noreply, redirect(socket, to: "/#{socket.assigns.locale}/payment_options")}
    end
  end

  @impl true
  def handle_event("validate", %{"image" => image_params}, socket) do
    changeset =
      %Image{}
      |> Media.change_image(image_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"image" => image_params}, socket) do
    unless socket.assigns.current_user.is_generating or socket.assigns.current_user.relaxed_mode do
      %{"prompt_id" => prompt_id} = image_params
      model_name = socket.assigns.selected_model.name
      image_params = %{image_params | "model_name" => model_name}
      prompt = Metadata.get_prompt!(prompt_id)

      case Media.create_image(socket.assigns.current_user, prompt, image_params) do
        {:ok, image} ->
          CoverGen.create_new(image: image)

          socket = socket |> assign(image: image, is_generating: true, gen_error: nil)

          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} ->
          IO.inspect(changeset)
          placeholder = random_placeholder(socket.assigns.locale, socket.assigns.lit_ai)
          {:noreply, assign(socket, changeset: changeset, placeholder: placeholder)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "aspect-ratio-change",
        %{"aspect_ratio" => aspect_ratio},
        socket
      ) do
    {width, height} = get_width_and_height(aspect_ratio)
    {:noreply, assign(socket, aspect_ratio: aspect_ratio, width: width, height: height)}
  end

  def handle_event("toggle-change", %{"toggle" => toggle}, socket) do
    toggle = if toggle == "1", do: true, else: false

    {:noreply,
     assign(socket, lit_ai: toggle, placeholder: random_placeholder(socket.assigns.locale, toggle))}
  end

  def handle_event("toggle-favorite", %{"image_id" => image_id}, socket) do
    image = Media.get_image!(image_id)

    case Media.update_image(image, %{favorite: !image.favorite}) do
      {:ok, image} ->
        {:noreply, assign(socket, :image, image)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("set_stage", %{"stage" => stage}, socket) do
    stage = get_stage(stage |> String.to_integer())
    socket = assign(socket, stage: stage)
    {:noreply, socket}
  end

  def handle_event("select-model", %{"model" => model_name}, socket) do
    model = get_model(model_name)
    socket = assign(socket, selected_model: model)
    {:noreply, socket}
  end

  def handle_event("change_gender", %{"gender" => gender}, socket) do
    socket =
      socket
      |> assign(gender: gender)

    {:noreply, socket}
  end

  def handle_event("next", %{"value" => value}, socket) do
    case socket.assigns.stage.id do
      0 ->
        stage = get_stage(socket.assigns.stage.id + 1)

        socket =
          socket
          |> assign(
            stage: stage,
            type: value
          )

        {:noreply, socket}

      1 ->
        stage = get_stage(socket.assigns.stage.id + 1)

        socket =
          socket
          |> assign(
            stage: stage,
            realm: value
          )

        {:noreply, socket}

      2 ->
        stage = get_stage(socket.assigns.stage.id + 1)

        style_prompts = Metadata.list_all_where(socket.assigns.realm, value, socket.assigns.type)

        socket =
          socket
          |> assign(
            stage: stage,
            sentiment: value,
            style_prompts: style_prompts
          )

        {:noreply, socket}

      3 ->
        prompt = Metadata.get_prompt!(value)

        model =
          if socket.assigns.type == "setting" do
            get_model("stable-diffusion")
          else
            get_model("couple5")
          end

        socket =
          socket
          |> assign(
            style_prompt: prompt.style_prompt,
            prompt_id: prompt.id,
            selected_model: model
          )

        {:noreply, socket}

      4 ->
        {:noreply, socket}
    end
  end

  def relaxed_mode_releaser(user, caller) do
    Task.start_link(fn ->
      # calculate difference
      now = NaiveDateTime.add(Timex.now(), 0)
      release_after = NaiveDateTime.diff(user.relaxed_mode_till, now, :millisecond)

      if release_after <= 0 do
        send(caller, {:end_relax, user})
      else
        release_after |> Process.sleep()
        send(caller, {:end_relax, user})
      end
    end)
  end

  def relaxed_mode_till(user) do
    now = NaiveDateTime.add(Timex.now(), 0)
    NaiveDateTime.diff(user.relaxed_mode_till, now, :millisecond)
  end

  defp check_new_payments(socket, caller) do
    Task.start_link(fn ->
      transactions = Payments.user_pending_transactions(socket.assigns.current_user)

      for transaction <- transactions do
        case Yookassa.Helpers.check_transaction(transaction) do
          {:ok, {:succeeded, litcoins}} ->
            Logger.info("Adding #{litcoins} litcoins to user #{socket.assigns.current_user.id}")
            params = %{relaxed_mode: false, recent_generations: 0}
            {:ok, _user} = Accounts.update_relaxed_mode(socket.assigns.current_user, params)
            {:ok, user} = Accounts.add_litcoins(socket.assigns.current_user, litcoins)
            send(caller, {:update_user, user})

          {:error, reason} ->
            Logger.error(
              "TransactionChecker: transaction #{transaction.id} check error: #{inspect(reason)}"
            )

          status ->
            Logger.info(
              "TransactionChecker: transaction #{transaction.id} status: #{inspect(status)}"
            )
        end
      end
    end)
  end

  defp get_width_and_height("cover") do
    {512, 768}
  end

  defp get_width_and_height("square") do
    {512, 512}
  end

  defp get_aspect_ratio({512, 768}) do
    "cover"
  end

  defp get_aspect_ratio({512, 512}) do
    "square"
  end

  attr(:aspect_ratio, :string, default: "cover")

  def img_dimensions(assigns) do
    ~H"""
    <div class="mb-10">
      <.header>
        <%= gettext("Step 2. ") %><span class="text-zinc-400 font-normal"><%= gettext("Image dimensions") %></span>
        <:subtitle><%= gettext("Choose what dimensions the image will have") %></:subtitle>
      </.header>
      <div class="flex gap-3 mt-5" x-data="">
        <div
          class="w-32 text-center px-4 py-2.5 cursor-pointer rounded-xl border-2 border-stroke-main bg-tag-main hover:border-accent-main transition"
          x-bind:class={"'#{@aspect_ratio}' == 'cover' && 'border-accent-main'"}
          phx-click="aspect-ratio-change"
          phx-value-aspect_ratio="cover"
        >
          2:3
        </div>
        <div
          class="w-32 text-center px-4 py-2.5 cursor-pointer rounded-xl border-2 border-stroke-main bg-tag-main hover:border-accent-main transition"
          x-bind:class={"'#{@aspect_ratio}' == 'square' && 'border-accent-main'"}
          phx-click="aspect-ratio-change"
          phx-value-aspect_ratio="square"
        >
          1:1
        </div>
        <!-- <div class="w-32 bg-zinc-600 opacity-50 flex items-center justify-center gap-1 px-4 py-2.5 cursor-pointer rounded-xl border-2 border-stroke-main bg-tag-main"> -->
        <!--   <.icon name="hero-lock-closed" class="w-5 h-5" /> <span>3:2</span> -->
        <!-- </div> -->
      </div>
    </div>
    """
  end

  def toggler(assigns) do
    ~H"""
    <div
      class="flex items-center justify-start"
      x-data="{ toggle: '0' }"
      x-init="() => { $watch('toggle', active => $dispatch('toggle-change', { toggle: active })) }"
      id="toggle-lit-ai"
      phx-hook="Toggle"
    >
      <div
        class="relative w-10 h-5 rounded-full transition duration-200 ease-linear"
        x-bind:class="[toggle === '1' ? 'bg-accent-main' : 'bg-dis-btn']"
      >
        <label
          for="toggle"
          class="absolute left-0 w-5 h-5 mb-2 bg-white border-2 rounded-full cursor-pointer transition transform duration-100 ease-linear"
          x-bind:class="[toggle === '1' ? 'translate-x-full border-accent-main' : 'translate-x-0 border-dis-btn']"
        >
        </label>
        <input type="hidden" value="off" />
        <input
          type="checkbox"
          id="toggle"
          class="hidden"
          x-on:click="toggle === '0' ? toggle = '1' : toggle = '0'"
        />
      </div>
    </div>
    """
  end

  attr(:spin, :boolean, default: false)
  attr(:relaxed_mode, :boolean, default: false)
  attr(:user_id, :string, required: true)
  attr :prompt_id, :integer, default: nil

  def generate_btn(assigns) do
    ~H"""
    <div
      x-data=""
      onclick="window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' })"
      class="pb-7 pt-12 flex"
    >
      <.button
        type="submit"
        class="btn-small flex items-center justify-center gap-3 py-3 bg-accent-main disabled:bg-zinc-600 disabled:opacity-50 disabled:hover:shadow-none rounded-full w-full"
        disabled={@spin or @relaxed_mode or @prompt_id == nil}
      >
        <span :if={@relaxed_mode} class="my-2" id={"relaxed-timer-user-#{@user_id}"}>00:00</span>
        <svg
          :if={!@relaxed_mode}
          x-bind:class={"#{@spin} && 'animate-slow-spin'"}
          xmlns="http://www.w3.org/2000/svg"
          width="14"
          height="14"
          fill="none"
        >
          <g clip-path="url(#a)">
            <g stroke="#fff" stroke-linecap="round" stroke-linejoin="round" clip-path="url(#b)">
              <path d="M12.917 2.333v3.5h-3.5M.083 11.667v-3.5h3.5" /><path d="M1.547 5.25a5.25 5.25 0 0 1 8.663-1.96l2.707 2.543M.083 8.167 2.79 10.71a5.25 5.25 0 0 0 8.663-1.96" />
            </g>
          </g>
          <defs>
            <clipPath id="a"><path fill="#fff" d="M0 0h14v14H0z" /></clipPath>
            <clipPath id="b"><path fill="#fff" d="M-.5 0h14v14h-14z" /></clipPath>
          </defs>
        </svg>
        <span :if={!@relaxed_mode} class="my-2"><%= gettext("Generate") %></span>
      </.button>
    </div>
    """
  end

  def stage_nav(assigns) do
    ~H"""
    <div class="mt-7 flex text-xs sm:text-sm leading-6 text-zinc-300">
      <%= for stage <- stages() do %>
        <%= if stage.id <= assigns.stage do %>
          <%= if stage.id == assigns.stage do %>
            <div class="cursor-pointer capitalize text-zinc-100 font-bold">
              <%= stage.name %>
            </div>
          <% else %>
            <div
              phx-click={
                JS.push("set_stage") |> JS.transition("opacity-0 translate-y-6", to: "#stage-box")
              }
              phx-value-stage={stage.id}
              class="cursor-pointer capitalize text-zinc-400 hover:text-zinc-100 font-light"
            >
              <%= stage.name %>
            </div>
          <% end %>
          <span class="last:hidden mx-2 text-zinc-400">></span>
        <% end %>
      <% end %>
    </div>
    """
  end

  def insert_tr(link, label) do
    tr =
      "tr:w-512,h-768,oi-vin.png,ow-512,oh-768,f-jpg,pr-true:ot-#{label},ots-30,otp-5_5_25_5,ofo-bottom,otc-fafafa"

    uri = link |> URI.parse()
    %URI{host: host, path: path} = uri

    {filename, list} = path |> String.split("/") |> List.pop_at(-1)
    folder = list |> List.last()
    bucket = "soulgenesis"

    case host do
      "ik.imagekit.io" ->
        Path.join(["https://", host, bucket, folder, tr, filename])

      _ ->
        link
    end
  end

  attr(:label, :string, default: nil)
  attr(:disabled, :boolean, default: false)

  def img_box(assigns) do
    assigns = assign_new(assigns, :prompt_id, fn -> nil end)
    assigns = assign_new(assigns, :value, fn -> nil end)
    assigns = assign_new(assigns, :stage_id, fn -> nil end)

    if assigns.value == nil do
      ~H"""
      <div></div>
      """
    else
      src = default_img_or(assigns.src)

      assigns = assign(assigns, :src, src)

      ~H"""
      <div
        id={"#{@src}"}
        class="aspect-cover relative group flex items-center justify-center mr-8 overflow-hidden rounded-xl border-2 border-stroke-main transition inline-block min-w-[150px] sm:min-w-fit sm:mr-0"
        x-bind:class={"{'border-accent-main': #{@value == @prompt_id}, 'hover:border-accent-main': #{!@disabled}, 'brightness-50 hover:brightness-100': #{@value != @prompt_id and @stage_id > 2}}"}
        x-data={"{ showImage: false, imageUrl: '#{@src}' }"}
        phx-click={next_stage_push_anim(@stage_id, @disabled)}
        phx-value-value={assigns.value}
      >
        <span
          :if={@stage_id < 3}
          x-bind:class={"'#{@disabled}' == 'true' ? 'inline-flex': 'hidden cursor-pointer'"}
          class={[
            "px-4 text-xs text-slate-200 absolute z-10",
            "group-hover:flex flex-col gap-2 items-center"
          ]}
        >
          <.icon :if={@disabled} name="hero-lock-closed-solid" class="w-7 h-7" />
          <span :if={@disabled} class="text-xs"><%= gettext("(Coming soon)") %></span>
          <span><%= @label %></span>
        </span>
        <img
          x-show="showImage"
          x-transition.duration.500ms
          x-bind:src="imageUrl"
          x-on:load="showImage = true"
          alt={assigns.label}
          x-bind:class={"{'brightness-50': #{@disabled}, 'cursor-pointer hover:scale-[1.02]': #{!@disabled}, 'group-hover:brightness-50': #{@stage_id < 3}}"}
          class="w-full h-full transition duration-300 ease-out object-cover"
        />
      </div>
      """
    end
  end

  defp next_stage_push_anim(stage_id, disabled) do
    unless disabled do
      if stage_id >= 3 do
        JS.push("next")
      else
        JS.push("next") |> JS.transition("opacity-0 translate-y-6", to: "#stage-box")
      end
    end
  end

  defp default_img_or(img) do
    if img == nil do
      "https://ik.imagekit.io/soulgenesis/litnet/realm_fantasy.jpg"
    else
      img
    end
  end

  def gender_picker(assigns) do
    ~H"""
    <div x-data="" class="mt-5 mb-4 flex w-full gap-5">
      <span
        x-bind:class={"'#{assigns.gender}' == 'female' ? 'underline text-pink-600': ''"}
        class="cursor-pointer capitalize link"
        phx-click="change_gender"
        phx-value-gender={:female}
      >
        <%= gettext("Female") %>
      </span>
      <!-- <button class="capitalize link text-xl" phx-click="change_gender" phx-value-gender={:couple}> -->
      <!--   Пара -->
      <!-- </button> -->
      <span
        x-bind:class={"'#{assigns.gender}' == 'male' ? 'underline text-pink-600': ''"}
        class="cursor-pointer capitalize link"
        phx-click="change_gender"
        phx-value-gender={:male}
      >
        <%= gettext("Male") %>
      </span>
    </div>
    """
  end

  def stage_box(assigns) do
    ~H"""
    <div class="min-h-[250px] sm:min-h-full flex flex-nowrap sm:gap-5 overflow-x-scroll sm:overflow-x-hidden hide-scroll-bar sm:grid sm:grid-cols-3">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def stage_msg(assigns) do
    ~H"""
    <div class="mb-4">
      <h1 class="mt-2 text-sm leading-6 text-zinc-300">
        <%= assigns.msg %>
      </h1>
    </div>
    """
  end

  defp stages do
    [
      %{
        id: 0,
        name: gettext("Cover type"),
        msg: gettext("What type of cover is more suitable for your book?")
      },
      %{id: 1, name: gettext("World"), msg: gettext("What world is your book set in?")},
      %{id: 2, name: gettext("Vibe"), msg: gettext("What vibe does your book have?")},
      %{id: 3, name: gettext("Style"), msg: gettext("What style do you prefer?")},
      %{id: 4, name: nil, msg: nil}
    ]
  end

  defp get_stage(id) do
    Enum.find(stages(), fn stage -> stage.id == id end)
  end

  defp get_model(name) do
    Enum.find(Replicate.Model.list_all(), fn model -> model.name == name end)
  end

  def types() do
    [
      %{disabled: false, name: :setting, label: gettext("Setting")},
      %{disabled: false, name: :couple, label: gettext("Couple")},
      %{disabled: false, name: :portrait, label: gettext("Character")},
      %{disabled: true, name: :attribute, label: gettext("Attribute")},
      %{disabled: true, name: :abstract, label: gettext("Abstract")},
      %{disabled: true, name: :third_person, label: gettext("Third person")}
    ]
  end

  def realms() do
    [
      %{name: :fantasy, label: gettext("Fantasy - Past")},
      %{name: :realism, label: gettext("Realism - Present")},
      %{name: :futurism, label: gettext("Futurism - Future")}
    ]
  end

  def sentiments do
    [
      %{name: :positive, label: gettext("Warm - Bright")},
      %{name: :neutral, label: gettext("Natural - Neutral")},
      %{name: :negative, label: gettext("Brutal - Dark")}
    ]
  end

  defp list_style_prompts do
    case Metadata.list_all_where(:fantasy, :positive, :setting) do
      [] ->
        [
          %Prompt{
            name: "1",
            realm: :fantasy,
            sentiment: :positive,
            type: :portrait,
            style_prompt:
              "abstract beauty, approaching perfection, delicate, dynamic, highly detailed, digital painting, artstation, concept art, smooth, sharp focus, illustration, art by Carne Griffiths and Wadim Kashin, sharp focus, by pascal blanche rutkowski repin artstation hyperrealism painting concept art",
            image_url:
              "https://ik.imagekit.io/soulgenesis/ac2a0657-10c7-47eb-99e3-eaa754fc47af.jpg",
            secondary_url:
              "https://ik.imagekit.io/soulgenesis/3c1ad675-2921-49da-bf7b-a08daf25e2e8.jpg"
          }
        ]

      style_prompts ->
        style_prompts
    end
  end

  def random_placeholder("en", _lit_ai = true) do
    [
      %{
        title: "To Kill a Mockingbird",
        author: "Harper Lee",
        description: "A young girl's perspective on racial injustice in the American South."
      },
      %{
        title: "1984",
        author: "George Orwell",
        description:
          "A cautionary tale of a dystopian society controlled by a totalitarian regime."
      },
      %{
        title: "Pride and Prejudice",
        author: "Jane Austen",
        description:
          "A witty romance novel that satirizes the social norms of 19th-century England."
      },
      %{
        title: "The Catcher in the Rye",
        author: "J.D. Salinger",
        description:
          "A novel capturing the disillusionment and angst of teenage life in post-World War II America."
      },
      %{
        title: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        description:
          "A tragic love story set in the lavish world of the 1920s, exploring themes of wealth, status, and the American Dream."
      },
      %{
        title: "Moby-Dick",
        author: "Herman Melville",
        description:
          "A story of obsession, revenge, and the struggle between man and nature as a whaling ship pursues a white whale."
      },
      %{
        title: "The Adventures of Huckleberry Finn",
        author: "Mark Twain",
        description:
          "A classic novel about a young boy's journey down the Mississippi River, exploring themes of racism and social injustice."
      },
      %{
        title: "The Odyssey",
        author: "Homer",
        description:
          "An epic poem about the adventures of Odysseus as he tries to return home after the Trojan War."
      },
      %{
        title: "Jane Eyre",
        author: "Charlotte Bronte",
        description:
          "A bildungsroman novel about a young woman's journey to find love and independence in 19th-century England."
      },
      %{
        title: "One Hundred Years of Solitude",
        author: "Gabriel Garcia Marquez",
        description:
          "A magical realist novel chronicling the history of the Buendia family in the fictional town of Macondo."
      }
    ]
    |> Enum.random()
  end

  def random_placeholder("ru", _lit_ai = true) do
    [
      %{
        title: "Убить пересмешника",
        author: "Харпер Ли",
        description: "Взгляд молодой девушки на расовую несправедливость в Южной Америке."
      },
      %{
        title: "1984",
        author: "Джордж Оруэлл",
        description:
          "Роман-предостережение о дистопическом обществе, контролируемом тоталитарным режимом."
      },
      %{
        title: "Гордость и предубеждение",
        author: "Джейн Остин",
        description:
          "Остроумный роман о любви, который сатиризирует социальные нормы Англии XIX века."
      },
      %{
        title: "Над пропастью во ржи",
        author: "Джером Д. Сэлинджер",
        description:
          "Роман, в котором описывается разочарование в юношеской жизни в послевоенной Америке."
      },
      %{
        title: "Великий Гэтсби",
        author: "Фрэнсис Скотт Фицджеральд",
        description:
          "Трагическая история любви, происходящая в роскошном мире 1920-х годов, исследующая темы богатства, статуса и американской мечты."
      },
      %{
        title: "Моби Дик",
        author: "Герман Мелвилл",
        description:
          "История одержимости, мести и борьбы между человеком и природой, когда корабль на китобойной охоте преследует белого кита."
      },
      %{
        title: "Приключения Гекльберри Финна",
        author: "Марк Твен",
        description:
          "Классический роман о путешествии мальчика вниз по реке Миссисипи, исследуя темы расизма и социальной несправедливости."
      },
      %{
        title: "Одиссея",
        author: "Гомер",
        description:
          "Эпическое поэма об приключениях Одиссея, когда он пытается вернуться домой после Троянской войны."
      },
      %{
        title: "Джейн Эйр",
        author: "Шарлотта Бронте",
        description:
          "Роман о жизненном пути молодой женщины, которая пытается преодолеть невзгоды сиротства, находит любовь и ищет свое место в обществе в Англии XIX века."
      },
      %{
        title: "Война и мир",
        author: "Лев Толстой",
        description:
          "Эпический роман, охватывающий жизнь российского общества в период Наполеоновских войн, исследуя темы любви, войны, семьи и человеческого прогресса."
      }
    ]
    |> Enum.random()
  end

  def random_placeholder("en", _lit_ai = false) do
    [
      %{
        title: "To Kill a Mockingbird",
        author: "Harper Lee",
        description: "A black mockingbird perched on a tree branch against a blue sky."
      },
      %{
        title: "1984",
        author: "George Orwell",
        description:
          "A pair of eyes looking out from a screen with the word 'BIG BROTHER' in bold letters."
      },
      %{
        title: "Pride and Prejudice",
        author: "Jane Austen",
        description:
          "A woman in a blue dress walking in a garden with a man in a tailcoat and top hat."
      },
      %{
        title: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        description:
          "A man in a suit holding a champagne glass with a green light in the background."
      },
      %{
        title: "One Hundred Years of Solitude",
        author: "Gabriel García Márquez",
        description: "A tree with a face carved into its trunk surrounded by butterflies."
      },
      %{
        title: "Moby-Dick",
        author: "Herman Melville",
        description: "A whale tail breaking the surface of the water with a ship in the distance."
      },
      %{
        title: "The Catcher in the Rye",
        author: "J.D. Salinger",
        description:
          "A red hunting hat perched on a brick wall with a New York City skyline in the background."
      },
      %{
        title: "The Hobbit",
        author: "J.R.R. Tolkien",
        description: "A hobbit hole with a green door set into a grassy hillside."
      },
      %{
        title: "Wuthering Heights",
        author: "Emily Bronte",
        description: "A dark and stormy moor with a manor house in the distance."
      },
      %{
        title: "Frankenstein",
        author: "Mary Shelley",
        description: "A man made of stitched-together body parts against a stormy sky."
      }
    ]
    |> Enum.random()
  end

  def random_placeholder("ru", _lit_ai = false) do
    [
      %{
        title: "Убить пересмешника",
        author: "Харпер Ли",
        description: "Черный пересмешник, сидящий на ветке дерева на фоне голубого неба."
      },
      %{
        title: "1984",
        author: "Джордж Оруэлл",
        description:
          "Пара глаз, смотрящих из экрана, на котором написаны жирными буквами слова 'БОЛЬШОЙ БРАТ'."
      },
      %{
        title: "Гордость и предубеждение",
        author: "Джейн Остин",
        description:
          "Женщина в синем платье, идущая по саду, рядом с мужчиной в фраке и цилиндре."
      },
      %{
        title: "Великий Гэтсби",
        author: "Фрэнсис Скотт Фицджеральд",
        description: "Мужчина в костюме, держащий бокал шампанского, на фоне зеленого света."
      },
      %{
        title: "Сто лет одиночества",
        author: "Габриэль Гарсия Маркес",
        description: "Дерево с вырезанным лицом, окруженное бабочками."
      },
      %{
        title: "Моби Дик",
        author: "Герман Мелвилл",
        description: "Хвост кита, выходящий из воды, на фоне корабля вдали."
      },
      %{
        title: "Над пропастью во ржи",
        author: "Джером Д. Сэлинджер",
        description:
          "Красная охотничья шапка, стоящая на кирпичной стене, на фоне горизонта Нью-Йорка."
      },
      %{
        title: "Хоббит, или Туда и обратно",
        author: "Джон Р.Р. Толкин",
        description: "Нора хоббита с зеленой дверью, расположенная на склоне травяного холма."
      },
      %{
        title: "Грозовой перевал",
        author: "Эмили Бронте",
        description: "Темный и бурный болотистый край, на фоне поместья вдали."
      },
      %{
        title: "Франкенштейн, или Современный Прометей",
        author: "Мэри Шелли",
        description: "Рука, вытянутая из тьмы, держит воскрешенное тело на фоне молний и грозы."
      }
    ]
    |> Enum.random()
  end
end
