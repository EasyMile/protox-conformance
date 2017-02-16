defmodule Protox.Conformance.Mixfile do
  use Mix.Project

  def project do
    [app: :protox_conformance,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     escript: [main_module: Protox.Conformance.Escript.Main],
   ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:protox, ">= 0.0.0"},
    ]
  end
end
