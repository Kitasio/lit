defmodule LitcoversWeb.Router do
  use LitcoversWeb, :router
  import LitcoversWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LitcoversWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug LitcoversWeb.Plugs.CountRequests
  end

  pipeline :apply_discount do
    plug LitcoversWeb.Plugs.GetReferer
  end

  pipeline :set_locale do
    plug SetLocale,
      gettext: LitcoversWeb.Gettext,
      default_locale: "ru"
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Admin dashboard
  scope "/en/admin" do
    pipe_through [:browser, :require_authenticated_admin]

    live_dashboard "/dashboard", metrics: LitcoversWeb.Telemetry
    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end

  scope "/", LitcoversWeb do
    pipe_through [:browser, :set_locale]

    get "/", PageController, :dummy
  end

  scope "/:locale", LitcoversWeb do
    pipe_through [:browser, :set_locale]

    live "/", PageLive.Index, :index
  end

  # Authenticated routes

  scope "/:locale", LitcoversWeb do
    pipe_through [:browser, :set_locale, :require_authenticated_admin]

    live_session :is_admin, on_mount: [{LitcoversWeb.UserAuth, :is_admin}] do
      live "/admin", AdminLive.Index, :index
      live "/admin/feedback", AdminLive.Feedback
      live "/admin/images/:id", AdminLive.Image
      live "/admin/user/:id", AdminLive.User
      live "/admin/images_feed", AdminLive.ImagesFeed
      live "/admin/covers_feed", AdminLive.CoversFeed

      live "/prompts", PromptLive.Index, :index
      live "/prompts/new", PromptLive.Index, :new
      live "/prompts/:id/edit", PromptLive.Index, :edit

      live "/prompts/:id", PromptLive.Show, :show
      live "/prompts/:id/show/edit", PromptLive.Show, :edit

      live "/placeholders", PlaceholderLive.Index, :index
      live "/placeholders/new", PlaceholderLive.Index, :new
      live "/placeholders/:id/edit", PlaceholderLive.Index, :edit

      live "/placeholders/:id", PlaceholderLive.Show, :show
      live "/placeholders/:id/show/edit", PlaceholderLive.Show, :edit
    end
  end

  scope "/:locale", LitcoversWeb do
    pipe_through [:browser, :set_locale, :redirect_if_user_is_authenticated, :apply_discount]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LitcoversWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/:locale", LitcoversWeb do
    pipe_through [
      :browser,
      :set_locale,
      :require_authenticated_user,
      :require_confirmed_user,
      :enabled_user
    ]

    live_session :enabled_user,
      on_mount: [{LitcoversWeb.UserAuth, :enabled_user}] do
      live "/images/new", ImageLive.New, :index
      live "/images/new/feedback", ImageLive.New, :feedback
      live "/images/new/:image_id/redo", ImageLive.New, :redo
      live "/images/new/:image_id/correct", ImageLive.New, :correct

      live "/images", ImageLive.Index, :index
      live "/images/unlocked", ImageLive.Index, :unlocked
      live "/images/favorites", ImageLive.Index, :favorites
      live "/images/all", ImageLive.Index, :all

      live "/covers", CoverLive.Index, :index

      live "/payment_options", TransactionLive.Index, :index
    end
  end

  scope "/:locale", LitcoversWeb do
    pipe_through [
      :browser,
      :set_locale,
      :require_authenticated_user,
      :require_confirmed_user,
      :enabled_user
    ]

    live_session :unlocked_image,
      on_mount: [{LitcoversWeb.UserAuth, :unlocked_image}] do
      live "/images/:id/edit", ImageLive.Show, :show
    end
  end

  scope "/:locale", LitcoversWeb do
    pipe_through [:browser, :set_locale, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LitcoversWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/:locale", LitcoversWeb do
    pipe_through [:browser, :set_locale]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{LitcoversWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
