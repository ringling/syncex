defmodule Syncex.Mixfile do
  use Mix.Project

  def project do
    [app: :syncex,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :couchex, :couchbeam, :httpotion],
     mod: {Syncex, []}]
  end

  defp deps do
    [
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.0"},
      {:httpotion, "~> 1.0.0"},
      {:couchex, github: "ringling/couchex"},
      {:poison, github: "devinus/poison"},
      {:timex, "~> 0.13.3"},
      {:dotenv, "~> 0.0.4"}
    ]
  end
end
