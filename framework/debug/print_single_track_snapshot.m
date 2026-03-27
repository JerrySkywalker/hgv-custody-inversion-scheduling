function print_single_track_snapshot(snap)
%PRINT_SINGLE_TRACK_SNAPSHOT Pretty-print debug snapshot for CLI inspection.

fprintf('\n=== TRACK META ===\n');
disp(snap.track_meta)

fprintf('\n=== TRACK PAYLOAD ===\n');
disp(snap.track_payload)

fprintf('\n=== TARGET INIT ===\n');
disp(snap.target_init)

fprintf('\n=== TARGET REFERENCE ===\n');
disp(snap.target_reference)

fprintf('\n=== TARGET DYNAMICS ===\n');
disp(snap.target_dynamics)

fprintf('\n=== TARGET CONTROL PROFILE ===\n');
disp(snap.target_control_profile)

fprintf('\n=== CONSISTENCY CHECKS ===\n');
disp(snap.consistency_checks)

fprintf('\n=== TRAJECTORY HEAD ===\n');
disp(snap.traj_head)
end
