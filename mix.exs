defmodule Fluid.MixProject do
  use Mix.Project

  @version "0.0.1-dev"
  def project() do
    [
      app: :fluid,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Fluid",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application() do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps() do
    [
      {:ecto, "~> 2.2.0", potional: true},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:timex, "~> 3.0", only: :test}
    ]
  end

  defp description() do
    """
    Fluid is a library to create meaningful IDs easily.
    """
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "fluid",
      maintaners: ["Alex Castaño"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/alexcastano/fluid",
        "Author" => "https://alexcastano.com"
      }
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "Fluid",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/fluid",
      source_url: "https://github.com/alexcastano/fluid",
      extras: [
        "README.md"
      ]
    ]
  end
end
