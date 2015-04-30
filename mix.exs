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
      mod: { Syncex, [] },
      applications: app_list(Mix.env),
      env: [version: Mix.Project.config[:version], app_path: Mix.Project.app_path, environment: Mix.env]
    ]
  end

  defp app_list(:dev), do: [:dotenv | app_list]
  defp app_list(:test), do: [:dotenv | app_list]
  defp app_list(_), do: app_list
  defp app_list, do: [:logger, :couchex, :couchbeam, :httpotion, :jsx, :poison, :timex, :xml_builder, :amqp]

  defp deps do
    [
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.0"},
      {:httpotion, "~> 1.0.0"},
      {:couchex, github: "ringling/couchex"},
      {:poison, "~> 1.4.0", override: true},
      {:timex, "~> 0.13.3"},
      {:hackney, "~> 1.1.0", override: true},
      {:dotenv, "~> 0.0.4"},
      {:xml_builder, "~> 0.0.5"},
      {:amqp, "0.1.0"},
      {:exrm, "~> 0.14.16"},
      {:mock, "~> 0.1.0"},
      {:raven, github: "lokalebasen/raven-elixir"}
    ]
  end
end
