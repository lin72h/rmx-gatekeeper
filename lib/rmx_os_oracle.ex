defmodule RmxOSOracle do
  @moduledoc """
  Oracle scaffold for rx/mx/nx behavior validation.

  M1 owns the Elixir/Zig harness layer only. Platform claims still require the
  evidence ladder described in `RmxOSOracle.Evidence`.
  """

  @app :rmxos_oracle
  @namespace "RmxOSOracle"
  @elixir_baseline "1.20.0"
  @otp_baseline "29"

  def app, do: @app
  def namespace, do: @namespace
  def elixir_baseline, do: @elixir_baseline
  def otp_baseline, do: @otp_baseline
end
