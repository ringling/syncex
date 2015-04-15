defmodule Syncex.Mixfile do
  use Mix.Project

  def project do
    [app: :syncex,
     version: "0.0.4",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [
      mod: {Syncex, []},
      applications: [:logger, :couchex, :couchbeam, :httpotion, :jsx, :dotenv, :poison, :timex, :xml_builder, :amqp],
      env: [version: Mix.Project.config[:version], app_path: Mix.Project.app_path, environment: Mix.env]
   ]
  end

  defp deps do
    [
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.0"},
      {:httpotion, "~> 1.0.0"},
      {:couchex, github: "ringling/couchex"},
      {:poison, github: "devinus/poison"},
      {:timex, "~> 0.13.3"},
      {:dotenv, "~> 0.0.4"},
      {:xml_builder, "~> 0.0.5"},
      {:amqp, "0.1.0"},
      {:exrm, "~> 0.14.16"}
    ]
  end
end
