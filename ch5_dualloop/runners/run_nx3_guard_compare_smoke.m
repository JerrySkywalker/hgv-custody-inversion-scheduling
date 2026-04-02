function out = run_nx3_guard_compare_smoke(scene_preset, verbose)
%RUN_NX3_GUARD_COMPARE_SMOKE
% NX-3 first round
% Compare:
%   - NX2-final: dwell=16, guard=false
%   - NX3-guarded: dwell=16, composite guard=true

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2
    verbose = true;
end

cfgA = default_ch5_params(scene_preset);
cfgA = apply_nx2_state_machine_defaults(cfgA);
cfgA = apply_nx3_guard_defaults(cfgA);
cfgA.ch5.nx2_dwell_steps = 16;
cfgA.ch5.nx3_guard_enable = false;
cfgA.ch5.nx2_guard_enable = false;

cfgB = default_ch5_params(scene_preset);
cfgB = apply_nx2_state_machine_defaults(cfgB);
cfgB = apply_nx3_guard_defaults(cfgB);
cfgB.ch5.nx2_dwell_steps = 16;
cfgB.ch5.nx3_guard_enable = true;
cfgB.ch5.nx2_guard_enable = true;

outA = run_ch5_phase7A_dualloop_ck(cfgA, false);
SA = load(outA.mat_file);

outB = run_ch5_phase7A_dualloop_ck(cfgB, false);
SB = load(outB.mat_file);

records_cell = cell(1,2);
records_cell{1} = local_pack_record('NX2-final', scene_preset, SA);
records_cell{2} = local_pack_record('NX3-guarded', scene_preset, SB);
records = [records_cell{:}];

if verbose
    disp('=== NX-3 guard compare ===')
    disp(struct2table(records))
end

out = struct();
out.records = records;
out.outA = outA;
out.outB = outB;
end

function r = local_pack_record(name, scene_preset, S)
r = struct();
r.name = string(name);
r.scene_preset = string(scene_preset);
r.q_worst_window = S.custodyCK.q_worst_window;
r.outage_ratio = S.custodyCK.outage_ratio;
r.longest_outage_steps = S.custodyCK.longest_outage_steps;
r.mean_rmse = S.trackingStatsCK.mean_rmse;
r.switch_count = local_count_switches(S.trackingCK);
r.applied_switch_count = local_count_applied_switches(S.trackingCK);
end

function n = local_count_switches(trackingCK)
n = 0;
if isfield(trackingCK, 'selected_sets')
    ss = trackingCK.selected_sets;
    for i = 2:numel(ss)
        n = n + ~isequal(ss{i-1}, ss{i});
    end
end
end

function n = local_count_applied_switches(trackingCK)
n = NaN;
if isfield(trackingCK, 'switch_applied')
    n = sum(trackingCK.switch_applied(:) ~= 0);
end
end
