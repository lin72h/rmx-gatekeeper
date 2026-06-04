defmodule Phase08SourceTransformTest do
  use ExUnit.Case, async: true

  alias Phase08.SourceTransform
  alias Phase08.Transform

  test "insert_before uses exact anchor and surrounding context" do
    source = "before\nanchor\nsince\n"

    transform =
      Transform.insert_before(:unit_before,
        anchor: "anchor\n",
        context_before: "before\n",
        context_after: "since\n",
        insert: "inserted\n"
      )

    assert {generated, [report]} = SourceTransform.apply_transforms(source, [transform])
    assert generated == "before\ninserted\nanchor\nsince\n"
    assert report.id == :unit_before
    assert report.line == 2
    assert report.position == :before
    assert report.inserted_bytes == byte_size("inserted\n")
  end

  test "insert_after inserts immediately after the exact anchor" do
    source = "before\nanchor\nsince\n"

    transform =
      Transform.insert_after(:unit_after,
        anchor: "anchor\n",
        context: :none,
        insert: "inserted\n"
      )

    assert {generated, [report]} = SourceTransform.apply_transforms(source, [transform])
    assert generated == "before\nanchor\ninserted\nsince\n"
    assert report.position == :after
  end

  test "legacy map transforms remain supported" do
    source = "a\nb\n"
    transform = %{id: :legacy_map, anchor: "a\n", position: :after, insert: "x\n"}

    assert {generated, [_report]} = SourceTransform.apply_transforms(source, [transform])
    assert generated == "a\nx\nb\n"
  end

  test "missing anchor fails loudly" do
    transform =
      Transform.insert_after(:missing,
        anchor: "absent",
        context: :none,
        insert: "x"
      )

    assert_raise ArgumentError, ~r/anchor :missing expected exactly one match, got 0/, fn ->
      SourceTransform.apply_transforms("source", [transform])
    end
  end

  test "duplicate anchor fails loudly" do
    transform =
      Transform.insert_after(:duplicate,
        anchor: "anchor",
        context: :none,
        insert: "x"
      )

    assert_raise ArgumentError, ~r/anchor :duplicate expected exactly one match, got 2/, fn ->
      SourceTransform.apply_transforms("anchor\nanchor\n", [transform])
    end
  end

  test "missing context_before fails loudly" do
    transform =
      Transform.insert_after(:bad_before,
        anchor: "anchor\n",
        context_before: "required-before",
        insert: "x"
      )

    assert_raise ArgumentError, ~r/missing context_before/, fn ->
      SourceTransform.apply_transforms("actual-before\nanchor\n", [transform])
    end
  end

  test "mismatched context_before fails loudly when anchor still matches" do
    transform =
      Transform.insert_after(:mismatch_before,
        anchor: "anchor\n",
        context_before: "expected-before\n",
        insert: "x"
      )

    assert_raise ArgumentError, ~r/missing context_before/, fn ->
      SourceTransform.apply_transforms("actual-before\nanchor\n", [transform])
    end
  end

  test "missing context_after fails loudly" do
    transform =
      Transform.insert_after(:bad_after,
        anchor: "anchor\n",
        context_after: "required-after",
        insert: "x"
      )

    assert_raise ArgumentError, ~r/missing context_after/, fn ->
      SourceTransform.apply_transforms("anchor\nactual-after\n", [transform])
    end
  end

  test "mismatched context_after fails loudly when anchor still matches" do
    transform =
      Transform.insert_after(:mismatch_after,
        anchor: "anchor\n",
        context_after: "expected-after\n",
        insert: "x"
      )

    assert_raise ArgumentError, ~r/missing context_after/, fn ->
      SourceTransform.apply_transforms("anchor\nactual-after\n", [transform])
    end
  end

  test "transform constructors validate required fields and position" do
    assert_raise ArgumentError, ~r/missing transform option :anchor/, fn ->
      Transform.insert_after(:bad, insert: "x")
    end

    assert_raise ArgumentError, ~r/unsupported position :middle/, fn ->
      Transform.build(:bad, anchor: "a", insert: "x", position: :middle, context: :none)
    end

    assert_raise ArgumentError,
                 ~r/requires context_before\/context_after or explicit context: :none/,
                 fn ->
                   Transform.insert_after(:bad_context, anchor: "a", insert: "x")
                 end
  end

  test "empty source fails gracefully" do
    transform =
      Transform.insert_after(:empty_source,
        anchor: "anchor",
        context: :none,
        insert: "x"
      )

    assert_raise ArgumentError, ~r/anchor :empty_source expected exactly one match, got 0/, fn ->
      SourceTransform.apply_transforms("", [transform])
    end
  end

  test "manifest emits C printf strings from marker ids" do
    assert Phase08.MarkerManifest.emit_c(:d23_inert_reload_accepted, "accepted ? 1 : 0", "%d") ==
             ~s|printf("PHASE08_D23_INERT_RELOAD_ACCEPTED=%d\\n", accepted ? 1 : 0);|
  end

  test "manifest validates static emit_c values against verifier policy" do
    assert Phase08.MarkerManifest.emit_c(:d23_inert_reload_accepted, "1", fmt: "%d", value: "1") ==
             ~s|printf("PHASE08_D23_INERT_RELOAD_ACCEPTED=%d\\n", 1);|

    assert_raise ArgumentError, ~r/emit_c value "0" != manifest expected "1"/, fn ->
      Phase08.MarkerManifest.emit_c(:d23_inert_reload_accepted, "0", fmt: "%d", value: "0")
    end
  end

  test "manifest emit_c rejects unknown ids and invalid value expressions" do
    assert_raise ArgumentError, ~r/unknown Phase 0.8 marker id: :missing_marker/, fn ->
      Phase08.MarkerManifest.emit_c(:missing_marker, "1", "%d")
    end

    assert_raise ArgumentError, ~r/requires a binary value expression/, fn ->
      Phase08.MarkerManifest.emit_c(:d23_inert_reload_accepted, nil, "%d")
    end

    assert_raise ArgumentError, ~r/requires a non-empty value expression/, fn ->
      Phase08.MarkerManifest.emit_c(:d23_inert_reload_accepted, "", "%d")
    end
  end

  test "manifest C string escaping handles quotes, backslash, newline, tab, and percent" do
    assert Phase08.MarkerManifest.c_string_literal("quote\" slash\\ newline\n tab\t percent%") ==
             ~s|"quote\\" slash\\\\ newline\\n tab\\t percent%"|

    assert Phase08.MarkerManifest.emit_c(:d23_inert_reload_accepted, "1", "%d") ==
             ~s|printf("PHASE08_D23_INERT_RELOAD_ACCEPTED=%d\\n", 1);|
  end
end
