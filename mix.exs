defmodule Littlechat.MixProject do
  use Mix.Project

  def project do
    [
      app: :littlechat,
      version: "0.5.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        littlechat: [
          include_erts: true,
          include_executables_for: [:unix],
          applications: [
            runtime_tools: :permanent
          ]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Littlechat.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.4"},
      {:phoenix_ecto, "~> 4.2"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.14.4"},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:distillery, "~> 2.0"},
      # See https://github.com/processone/ejabberd/issues/1107#issuecomment-217828211 if you have errors installing stun on macOS.
      {:stun, "~> 1.0"},
      {:sentry, "~> 8.0-rc.2"},
      {:hackney, "~> 1.8"}
      # install ngrok https://github.com/joshuafleck/ex_ngrok#dependencies and
      # uncomment the ex_ngrok dependency and do a mix deps.get to enable ex_ngrok
      # and facilitate iOS device testing which requires https
      # access the unique ngrok URL displayed upon app start on your device:
      # ..
      # Generated littlechat app
      # [info] ex_ngrok: Ngrok tunnel available at https://xyz.ngrok.io
      # ..
      # (NB the URL changes upon each app start on free tier and is limited to 4 connections - https://ngrok.com/pricing
      # eg. use localhost on your dev computer)
      # can also be useful for testing between different and remote networks
      # {:ex_ngrok, "~> 0.3.0", only: [:dev]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
