defmodule RmxOSOracleStable15EnvMatrixTest do
  use ExUnit.Case

  alias RmxOSOracle.Stable15.EnvMatrix

  test "stable15 env matrix passes expected positive and negative cases" do
    report = EnvMatrix.run()

    assert report["status"] == "pass"
    assert report["case_count"] == 14
    assert report["guest_run_performed"] == false
    assert report["certification_claim"] == false

    by_id = Map.new(report["cases"], &{&1["id"], &1})

    assert by_id["default_stable15_active_launchd"]["observed"]["accepted_source_profile"] ==
             "stable15-active"

    assert by_id["default_stable15_active_launchd"]["observed"]["source_pin_id"] ==
             "stable15-active"

    assert by_id["default_stable15_active_launchd"]["observed"]["freebsd_src"] ==
             "/Users/me/wip-mach/freebsd-src-official-stable-15"

    assert by_id["default_stable15_active_launchd"]["observed"]["freebsd_src_commit"] ==
             "f71260cf4c9e"

    assert by_id["default_stable15_active_launchd"]["observed"][
             "expected_freebsd_src_commit"
           ] == "f71260cf4c9e"

    assert by_id["default_stable15_active_launchd"]["observed"]["kernel_objdirprefix"] ==
             "/Users/me/wip-mach/build/official-stable15-mach-obj"

    assert by_id["official_stable15_candidate_alias"]["observed"]["freebsd_src"] ==
             by_id["explicit_stable15_active"]["observed"]["freebsd_src"]

    assert by_id["official_stable15_candidate_alias"]["observed"]["kernel_objdirprefix"] ==
             by_id["explicit_stable15_active"]["observed"]["kernel_objdirprefix"]

    assert by_id["explicit_releng151_current"]["observed"]["accepted_source_profile"] ==
             "releng151-current"

    assert by_id["default_profile_releng151_objdir"]["actual_status"] == "fail"
    assert by_id["default_profile_usrobj"]["actual_status"] == "fail"
    assert by_id["stable15_active_releng_source"]["actual_status"] == "fail"
    assert by_id["stable15_active_releng_objdir"]["actual_status"] == "fail"
    assert by_id["candidate_alias_releng_objdir"]["actual_status"] == "fail"
    assert by_id["unknown_profile"]["actual_status"] == "fail"
  end
end
