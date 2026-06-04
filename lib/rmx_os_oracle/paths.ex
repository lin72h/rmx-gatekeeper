defmodule RmxOSOracle.Paths do
  @moduledoc """
  Path validation helpers for oracle-owned tasks.
  """

  def absolute?(path), do: is_binary(path) and Path.type(path) == :absolute

  def exists_dir?(path), do: is_binary(path) and File.dir?(path)

  def symlink?(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :symlink}} -> true
      _ -> false
    end
  end

  def expand_config_path(path, env) when is_binary(path) do
    env
    |> Enum.reduce(path, fn {key, value}, acc ->
      String.replace(acc, "${#{key}}", value)
    end)
    |> Path.expand()
  end

  def oracle_root, do: File.cwd!()

  def under?(path, parent) do
    path = Path.expand(path)
    parent = Path.expand(parent)
    path == parent or String.starts_with?(path, parent <> "/")
  end
end
