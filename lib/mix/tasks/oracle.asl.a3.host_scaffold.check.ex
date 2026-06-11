defmodule Mix.Tasks.Oracle.Asl.A3.HostScaffold.Check do
  @moduledoc """
  Validate source-owned ASL A3 host-scaffold preflight output.

  Usage:

      mix oracle.asl.a3.host_scaffold.check --preflight path/to/preflight.log --source-pin SHA

  This task reads an existing preflight log. It does not run source scripts, does
  not run guests, and does not create marker authority.
  """

  use Mix.Task

  alias RmxOSOracle.Asl.A3.HostScaffoldContract
  alias RmxOSOracle.CanonicalJSON

  @shortdoc "Validate ASL A3 host-scaffold preflight output"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, invalid} =
      OptionParser.parse(args,
        strict: [preflight: :string, source_pin: :string, json: :boolean]
      )

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    preflight = Keyword.get(opts, :preflight) || Mix.raise("missing --preflight")
    source_pin = Keyword.get(opts, :source_pin)

    report =
      preflight
      |> File.read!()
      |> HostScaffoldContract.validate_preflight(source_pin: source_pin)

    if Keyword.get(opts, :json, false) do
      Mix.shell().info(CanonicalJSON.encode!(report))
    else
      print_report(report)
    end

    unless report["passed"] do
      Mix.raise("ASL A3 host-scaffold preflight check failed")
    end
  end

  defp print_report(report) do
    Mix.shell().info("oracle.asl.a3.host_scaffold.check: #{status(report)}")
    Mix.shell().info("  guest_authorized: #{report["guest_authorized"]}")
    Mix.shell().info("  marker_authority: #{report["marker_authority"]}")

    Enum.each(report["warnings"], fn warning ->
      Mix.shell().info("  warning: #{warning}")
    end)

    Enum.each(report["errors"], fn error ->
      Mix.shell().error("  failure: #{error}")
    end)
  end

  defp status(%{"passed" => true}), do: "pass"
  defp status(%{"passed" => false}), do: "fail"
end
