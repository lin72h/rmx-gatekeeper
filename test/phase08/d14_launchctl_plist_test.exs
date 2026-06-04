defmodule Phase08D14LaunchctlPlistTest do
  use ExUnit.Case, async: true

  alias RmxOSOracle.Migration.Phase08D14LaunchctlPlist

  test "marker validator accepts the D14 contract shape" do
    log = passing_serial_log()

    assert %{"passed" => true, "missing" => []} =
             Phase08D14LaunchctlPlist.validate_serial_log(log)
  end

  test "hard-stop scan rejects D14 failure markers" do
    scan =
      Phase08D14LaunchctlPlist.hard_stop_scan(
        passing_serial_log() <> "\nPHASE08_D14_JOB_START_CALLED=1\n"
      )

    refute scan["passed"]
    assert Enum.any?(scan["matches"], &(&1["group"] == "d14"))
  end

  test "hard-stop scan allows normal WITNESS enabled boot warning" do
    scan =
      Phase08D14LaunchctlPlist.hard_stop_scan(
        "WARNING: WITNESS option enabled, expect reduced performance.\n"
      )

    assert scan["passed"]
  end

  test "negative control removes the D14 confirmed marker and fails red" do
    dir =
      Path.join(
        System.tmp_dir!(),
        "rmxos-oracle-d14-negative-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)

    try do
      assert %{"passed" => true, "marker_specific_failure" => true} =
               Phase08D14LaunchctlPlist.run_negative_control!(passing_serial_log(), dir)
    after
      File.rm_rf!(dir)
    end
  end

  test "boot identity requires mach_module loaded marker" do
    dir =
      Path.join(
        System.tmp_dir!(),
        "rmxos-oracle-d14-boot-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)

    kernel = Path.join(dir, "kernel")
    mach_ko = Path.join(dir, "mach.ko")
    guest_image = Path.join(dir, "guest.img")

    File.write!(kernel, "kernel")
    File.write!(mach_ko, "mach")
    File.write!(guest_image, "guest")

    env = %{
      "freebsd_src_commit" => "abc1234",
      "resolved" => %{
        "base_profile" => "test",
        "NXPLATFORM_FREEBSD_SRC" => "/tmp/freebsd-src",
        "NXPLATFORM_KERNEL_OBJDIRPREFIX" => "/tmp/obj",
        "NXPLATFORM_KERNEL_CONF" => "MACHDEBUGDEBUG",
        "kernel_path" => kernel,
        "mach_ko_path" => mach_ko,
        "vm_image" => guest_image
      }
    }

    try do
      assert %{
               "passed" => true,
               "freebsd_src_commit" => "abc1234",
               "legacy_test_commit" => "a30ef3f",
               "hash_requirements" => requirements
             } = Phase08D14LaunchctlPlist.boot_identity(env, "mach_module=loaded\n")

      assert Enum.all?(requirements, & &1["passed"])
      assert %{"passed" => false} = Phase08D14LaunchctlPlist.boot_identity(env, "booted\n")

      File.rm!(guest_image)

      assert %{"passed" => false} =
               Phase08D14LaunchctlPlist.boot_identity(env, "mach_module=loaded\n")
    after
      File.rm_rf!(dir)
    end
  end

  defp passing_serial_log do
    markers =
      Phase08D14LaunchctlPlist.required_exact_markers() ++
        Phase08D14LaunchctlPlist.required_regex_marker_samples()

    Enum.join(markers, "\n") <> "\n"
  end
end
