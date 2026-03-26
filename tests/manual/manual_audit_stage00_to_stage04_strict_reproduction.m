function audit = manual_audit_stage00_to_stage04_strict_reproduction()
startup;

audit = struct();
audit.generated_at = string(datetime('now'));

% Reuse the existing manual regression harness as the current evidence base.
reg = manual_framework_vs_legacy_manual_regression();

audit.stage00 = struct();
audit.stage00.status = "manual_check_required";
audit.stage00.note = "Stage00 is configuration/bootstrap only; verify cfg/path semantics separately.";

audit.stage01 = reg.stage01;
audit.stage02 = reg.stage02;
audit.stage03_resource = reg.stage03_resource;
audit.stage03_visibility = reg.stage03_visibility;
audit.stage04_window = reg.stage04_window;

disp('[audit] Stage00-Stage04 strict reproduction audit summary');
disp(table( ...
    ["stage00"; "stage01"; "stage02"; "stage03_resource"; "stage03_visibility"; "stage04_window"], ...
    ["manual_check_required"; "covered_by_regression"; "covered_by_regression"; "covered_by_regression"; "covered_by_regression"; "covered_by_regression"], ...
    'VariableNames', {'stage_name','status'}));

disp('[audit] Existing regression coverage object:');
disp(audit);
end
