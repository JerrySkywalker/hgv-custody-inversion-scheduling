function out = run_nx3_guard_action_compare(scene_preset, verbose)
%RUN_NX3_GUARD_ACTION_COMPARE
% NX-3 second round
% Compare:
%   - NX3-base       : composite guard, no action coupling
%   - NX3-A-freeze   : composite guard + freeze selection
%   - NX3-B-degrade  : composite guard + degrade mode

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2
    verbose = true;
end

cfgBase = local_make_cfg(scene_preset, 'none');
cfgA    = local_make_cfg(scene_preset, 'freeze_selection');
cfgB    = local_make_cfg(scene_preset, 'degrade_mode');

outBase = run_ch5_phase7A_dualloop_ck(cfgBase, false);
SBase = load(outBase.mat_file);

outA = run_ch5_phase7A_dualloop_ck(cfgA, false);
SA = load(outA.mat_file);

outB = run_ch5_phase7A_dualloop_ck(cfgB, false);
SB = load(outB.mat_file);

records_cell = cell(1,3);
records_cell{1} = local_pack_record('NX3-base', scene_preset, SBase);
records_cell{2} = local_pack_record('NX3-A-freeze', scene_preset, SA);
records_cell{3} = local_pack_record('NX3-B-degrade', scene_preset, SB);
records = [records_cell{:}];

if verbose
    disp('=== NX-3 guard action compare ===')
    disp(struct2table(records))
end

out = struct();
out.records = records;
out.outBase = outBase;
out.outA = outA;
out.outB = outB;
end

function cfg = local_make_cfg(scene_preset, action_mode)
cfg = default_ch5_params(scene_preset);
cfg = apply_nx2_state_machine_defaults(cfg);
cfg = apply_nx3_guard_defaults(cfg);
cfg = apply_nx3_guard_action_defaults(cfg);

cfg.ch5.nx2_dwell_steps = 16;
cfg.ch5.nx2_guard_enable = true;
cfg.ch5.nx3_guard_enable = true;
cfg.ch5.nx3_guard_action_mode = action_mode;
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
