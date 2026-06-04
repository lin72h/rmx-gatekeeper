defmodule Phase08.Transform do
  @moduledoc false

  @enforce_keys [:id, :anchor, :insert]
  defstruct [
    :id,
    :anchor,
    :insert,
    position: :after,
    context: nil,
    context_before: nil,
    context_after: nil,
    context_window: 8
  ]

  def insert_before(id, opts) when is_atom(id) and is_list(opts) do
    build(id, Keyword.put(opts, :position, :before))
  end

  def insert_after(id, opts) when is_atom(id) and is_list(opts) do
    build(id, Keyword.put(opts, :position, :after))
  end

  def build(id, opts) when is_atom(id) and is_list(opts) do
    transform = %__MODULE__{
      id: id,
      anchor: fetch_opt!(opts, :anchor),
      insert: fetch_opt!(opts, :insert),
      position: Keyword.get(opts, :position, :after),
      context: Keyword.get(opts, :context),
      context_before: Keyword.get(opts, :context_before),
      context_after: Keyword.get(opts, :context_after),
      context_window: Keyword.get(opts, :context_window, 8)
    }

    validate!(transform)
  end

  def validate!(%__MODULE__{} = transform) do
    unless is_binary(transform.anchor) and transform.anchor != "" do
      raise ArgumentError, "transform #{inspect(transform.id)} requires a non-empty binary anchor"
    end

    unless is_binary(transform.insert) do
      raise ArgumentError, "transform #{inspect(transform.id)} requires a binary insert"
    end

    if transform.context_before == nil and transform.context_after == nil and
         transform.context != :none do
      raise ArgumentError,
            "transform #{inspect(transform.id)} requires context_before/context_after or explicit context: :none"
    end

    if transform.context not in [nil, :none] do
      raise ArgumentError,
            "transform #{inspect(transform.id)} has unsupported context #{inspect(transform.context)}"
    end

    unless transform.position in [:before, :after] do
      raise ArgumentError,
            "transform #{inspect(transform.id)} has unsupported position #{inspect(transform.position)}"
    end

    unless is_integer(transform.context_window) and transform.context_window > 0 do
      raise ArgumentError,
            "transform #{inspect(transform.id)} requires a positive integer context_window"
    end

    transform
  end

  defp fetch_opt!(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "missing transform option #{inspect(key)}"
    end
  end
end

defmodule Phase08.SourceTransform do
  @moduledoc false

  def apply_transforms(source, transforms) when is_binary(source) and is_list(transforms) do
    Enum.reduce(transforms, {source, []}, fn transform, {current, reports} ->
      {next, report} = apply_transform(current, transform)
      {next, reports ++ [report]}
    end)
  end

  def apply_transform(source, transform) do
    transform = normalize_transform!(transform)
    id = Map.fetch!(transform, :id)
    anchor = Map.fetch!(transform, :anchor)
    insert = Map.fetch!(transform, :insert)
    position = Map.get(transform, :position, :after)
    context_window = Map.get(transform, :context_window, 8)

    matches = match_offsets(source, anchor)

    unless length(matches) == 1 do
      raise ArgumentError,
            "anchor #{inspect(id)} expected exactly one match, got #{length(matches)}"
    end

    offset = hd(matches)
    assert_context!(source, offset, anchor, transform, context_window)

    next =
      case position do
        :before ->
          insert_at(source, offset, insert)

        :after ->
          insert_at(source, offset + byte_size(anchor), insert)

        other ->
          raise ArgumentError, "anchor #{inspect(id)} has unsupported position #{inspect(other)}"
      end

    line = line_number(source, offset)

    {next,
     %{
       id: id,
       line: line,
       anchor: anchor,
       position: position,
       inserted_bytes: byte_size(insert)
     }}
  end

  def assert_contains!(source, pattern, label) do
    unless String.contains?(source, pattern) do
      raise ArgumentError, "generated source missing #{label}: #{inspect(pattern)}"
    end
  end

  def match_offsets(source, pattern), do: match_offsets(source, pattern, 0, [])

  defp normalize_transform!(%Phase08.Transform{} = transform) do
    Phase08.Transform.validate!(transform)
    Map.from_struct(transform)
  end

  # Legacy map compatibility supports D22 parity and frozen gates. New generated
  # gates should use %Phase08.Transform{} so constructor validation runs.
  defp normalize_transform!(transform) when is_map(transform), do: transform

  defp match_offsets(source, pattern, offset, acc) do
    case :binary.match(source, pattern, scope: {offset, byte_size(source) - offset}) do
      {match_offset, _len} ->
        match_offsets(source, pattern, match_offset + byte_size(pattern), [match_offset | acc])

      :nomatch ->
        Enum.reverse(acc)
    end
  end

  defp assert_context!(source, offset, anchor, transform, context_window) do
    before_text = surrounding_before(source, offset, context_window)
    after_text = surrounding_after(source, offset + byte_size(anchor), context_window)

    case optional_context(transform, :context_before) do
      {:ok, expected} ->
        unless String.contains?(before_text, expected) do
          raise ArgumentError,
                "anchor #{inspect(transform.id)} missing context_before #{inspect(expected)}"
        end

      :error ->
        :ok
    end

    case optional_context(transform, :context_after) do
      {:ok, expected} ->
        unless String.contains?(after_text, expected) do
          raise ArgumentError,
                "anchor #{inspect(transform.id)} missing context_after #{inspect(expected)}"
        end

      :error ->
        :ok
    end
  end

  defp optional_context(transform, key) do
    case Map.get(transform, key) do
      nil ->
        :error

      value when is_binary(value) ->
        {:ok, value}

      value ->
        raise ArgumentError,
              "anchor #{inspect(transform.id)} has invalid #{key} #{inspect(value)}"
    end
  end

  defp surrounding_before(source, offset, line_count) do
    prefix = binary_part(source, 0, offset)

    prefix
    |> String.split("\n")
    |> Enum.take(-line_count)
    |> Enum.join("\n")
  end

  defp surrounding_after(source, offset, line_count) do
    suffix = binary_part(source, offset, byte_size(source) - offset)

    suffix
    |> String.split("\n")
    |> Enum.take(line_count)
    |> Enum.join("\n")
  end

  defp insert_at(source, offset, insert) do
    prefix = binary_part(source, 0, offset)
    suffix = binary_part(source, offset, byte_size(source) - offset)
    prefix <> insert <> suffix
  end

  defp line_number(source, offset) do
    source
    |> binary_part(0, offset)
    |> :binary.matches("\n")
    |> length()
    |> Kernel.+(1)
  end
end
