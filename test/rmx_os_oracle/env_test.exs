defmodule RmxOSOracleEnvTest do
  use ExUnit.Case

  alias RmxOSOracle.Env

  @workspace_root "/Users/me/wip-mach"
  @releng_src "/Users/me/wip-mach/wip-gpt/freebsd-src-stable-15"
  @candidate_src "/Users/me/wip-mach/freebsd-src-official-stable-15"
  @releng_objdir "/Users/me/wip-mach/build/releng151-mach-obj"
  @releng_rc1_objdir "/Users/me/wip-mach/build/releng151-rc1-mach-obj"
  @candidate_objdir "/Users/me/wip-mach/build/official-stable15-mach-obj"

  @nx_env_keys ~w(
    NXPLATFORM_BASE_PROFILE
    NXPLATFORM_WORKSPACE_ROOT
    NXPLATFORM_FREEBSD_SRC
    NXPLATFORM_KERNEL_OBJDIRPREFIX_CURRENT_TREE
    NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD
    NXPLATFORM_KERNEL_OBJDIRPREFIX_DISPATCH
    NXPLATFORM_KERNEL_OBJDIRPREFIX_LIBTHR
  )

  test "absent profile defaults to releng151-current source pin" do
    report =
      check_with_env(%{
        "NXPLATFORM_WORKSPACE_ROOT" => @workspace_root,
        "NXPLATFORM_FREEBSD_SRC" => @releng_src,
        "NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD" => @releng_objdir
      })

    assert report["status"] == "pass"
    assert report["accepted_source_profile"] == "releng151-current"
    assert report["source_pin_id"] == "releng151-current"
    assert report["freebsd_src"] == @releng_src
    assert report["kernel_objdirprefix"] == @releng_objdir
  end

  test "explicit releng151-current source pin passes" do
    report =
      check_with_env(%{
        "NXPLATFORM_BASE_PROFILE" => " releng151-current ",
        "NXPLATFORM_WORKSPACE_ROOT" => @workspace_root,
        "NXPLATFORM_FREEBSD_SRC" => @releng_src,
        "NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD" => @releng_objdir
      })

    assert report["status"] == "pass"
    assert report["accepted_source_profile"] == "releng151-current"
    assert report["freebsd_src"] == @releng_src
  end

  test "official stable15 candidate source pin requires exact source, commit, and objdir" do
    report =
      check_with_env(%{
        "NXPLATFORM_BASE_PROFILE" => "official-stable15-candidate",
        "NXPLATFORM_WORKSPACE_ROOT" => @workspace_root,
        "NXPLATFORM_FREEBSD_SRC" => @candidate_src,
        "NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD" => @candidate_objdir
      })

    assert report["status"] == "pass"
    assert report["accepted_source_profile"] == "official-stable15-candidate"
    assert report["source_pin_id"] == "official-stable15-candidate"
    assert report["freebsd_src"] == @candidate_src
    assert report["freebsd_src_commit"] == "63ce90100a4e"
    assert report["expected_freebsd_src_commit"] == "63ce90100a4e"
    assert report["kernel_objdirprefix"] == @candidate_objdir
  end

  test "candidate source path without profile fails closed" do
    report =
      check_with_env(%{
        "NXPLATFORM_WORKSPACE_ROOT" => @workspace_root,
        "NXPLATFORM_FREEBSD_SRC" => @candidate_src,
        "NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD" => @candidate_objdir
      })

    assert_failed_with(report, "NXPLATFORM_FREEBSD_SRC must match accepted source pin")
  end

  test "unknown source profile fails explicitly" do
    report =
      check_with_env(%{
        "NXPLATFORM_BASE_PROFILE" => "stable15-surprise",
        "NXPLATFORM_WORKSPACE_ROOT" => @workspace_root,
        "NXPLATFORM_FREEBSD_SRC" => @releng_src,
        "NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD" => @releng_objdir
      })

    assert_failed_with(report, "unknown NXPLATFORM_BASE_PROFILE: stable15-surprise")
  end

  test "unknown absolute source path fails source pin validation" do
    report =
      check_with_env(%{
        "NXPLATFORM_WORKSPACE_ROOT" => @workspace_root,
        "NXPLATFORM_FREEBSD_SRC" => @workspace_root,
        "NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD" => @releng_objdir
      })

    assert_failed_with(report, "NXPLATFORM_FREEBSD_SRC must match accepted source pin")
  end

  test "candidate profile rejects releng and default objdir prefixes" do
    for objdir <- [@releng_objdir, @releng_rc1_objdir, "/usr/obj"] do
      report =
        check_with_env(%{
          "NXPLATFORM_BASE_PROFILE" => "official-stable15-candidate",
          "NXPLATFORM_WORKSPACE_ROOT" => @workspace_root,
          "NXPLATFORM_FREEBSD_SRC" => @candidate_src,
          "NXPLATFORM_KERNEL_OBJDIRPREFIX_LAUNCHD" => objdir
        })

      assert_failed_with(
        report,
        "NXPLATFORM_KERNEL_OBJDIRPREFIX for official-stable15-candidate must be #{@candidate_objdir}"
      )
    end
  end

  defp check_with_env(env) do
    with_clean_nx_env(fn ->
      env_path = write_env_file!(env)
      Env.check("launchd", env_path: env_path)
    end)
  end

  defp write_env_file!(env) do
    dir = Path.join(System.tmp_dir!(), "rmxos-oracle-env-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    path = Path.join(dir, "env.local")

    body =
      env
      |> Enum.sort()
      |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)

    File.write!(path, body <> "\n")
    path
  end

  defp with_clean_nx_env(fun) do
    saved = Map.new(@nx_env_keys, &{&1, System.get_env(&1)})
    Enum.each(@nx_env_keys, &System.delete_env/1)

    try do
      fun.()
    after
      Enum.each(saved, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end
  end

  defp assert_failed_with(report, expected) do
    assert report["status"] == "fail"
    assert Enum.any?(report["errors"], &String.contains?(&1, expected))
  end
end
