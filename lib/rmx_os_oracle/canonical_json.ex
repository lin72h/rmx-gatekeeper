defmodule RmxOSOracle.CanonicalJSON do
  @moduledoc false

  def decode!(path_or_binary) when is_binary(path_or_binary) do
    data =
      if File.regular?(path_or_binary) do
        File.read!(path_or_binary)
      else
        path_or_binary
      end

    JSON.decode!(data)
  end

  def encode!(term), do: encode(term)

  def write!(path, term) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, encode!(term) <> "\n")
  end

  def sha256(term) do
    term
    |> encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp encode(map) when is_map(map) do
    entries =
      map
      |> Enum.map(fn {key, value} -> {to_string(key), value} end)
      |> Enum.sort_by(fn {key, _value} -> key end)

    "{" <>
      Enum.map_join(entries, ",", fn {key, value} ->
        encode_string(key) <> ":" <> encode(value)
      end) <> "}"
  end

  defp encode(list) when is_list(list), do: "[" <> Enum.map_join(list, ",", &encode/1) <> "]"
  defp encode(value) when is_binary(value), do: encode_string(value)
  defp encode(value) when is_integer(value), do: Integer.to_string(value)

  defp encode(value) when is_float(value),
    do: :erlang.float_to_binary(value, [:compact, decimals: 16])

  defp encode(true), do: "true"
  defp encode(false), do: "false"
  defp encode(nil), do: "null"
  defp encode(value) when is_atom(value), do: encode_string(Atom.to_string(value))

  defp encode_string(value) do
    "\"" <> escape_string(value) <> "\""
  end

  defp escape_string(value) do
    for <<cp::utf8 <- value>>, into: "" do
      case cp do
        ?" -> "\\\""
        ?\\ -> "\\\\"
        ?\b -> "\\b"
        ?\f -> "\\f"
        ?\n -> "\\n"
        ?\r -> "\\r"
        ?\t -> "\\t"
        cp when cp < 0x20 -> "\\u" <> String.pad_leading(Integer.to_string(cp, 16), 4, "0")
        cp -> <<cp::utf8>>
      end
    end
  end
end
