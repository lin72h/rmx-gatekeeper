defmodule RmxOSOracle.Fixtures do
  @moduledoc """
  Fixture inventory helpers for imported M1 fixture data.
  """

  @launchd_pattern "fixtures/launchd/*.{plist,json}"

  def launchd_files do
    @launchd_pattern
    |> Path.wildcard()
    |> Enum.sort()
  end

  def validate_launchd_fixtures do
    files = launchd_files()

    %{
      "schema" => "rmxos_oracle.fixture_check.v1",
      "status" => if(files == [], do: "fail", else: "pass"),
      "launchd_fixture_count" => length(files),
      "files" => files
    }
  end
end
