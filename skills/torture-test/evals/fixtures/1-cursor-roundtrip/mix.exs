defmodule Feed.MixProject do
  use Mix.Project

  def project do
    [app: :feed, version: "0.1.0", elixir: "~> 1.15", deps: deps()]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [{:stream_data, "~> 1.0", only: [:dev, :test]}]
  end
end
