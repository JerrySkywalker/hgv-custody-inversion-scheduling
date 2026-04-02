function out = run_nx4_soft_compare_smoke(scene_preset, verbose)
%RUN_NX4_SOFT_COMPARE_SMOKE
% NX-4 second round
% Compare:
%   - NX4-base          : no proposal coupling
%   - NX4-soft          : soft proposal coupling
%   - NX4-proposal-only : proposal layer only, no selection change, diagnostic only

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2
    verbose = true;
end

cfgBase = local_make_cfg(scene_preset, false);
cfgSoft = local_make_cfg(scene_preset, true);

outBase = run_ch5_phase7A_dualloop_ck(cfgBase, false);
SBase = load(outBase.mat_file);

outSoft = run_ch5_phase7A_dualloop_ck(cfgSoft, false);
SSoft = load(outSoft.mat_file);

proposalOnly = run_nx4_proposal_compare_smoke(scene_preset, 10, false);

records_cell = cell(1,3);
records_cell{1} = local_pack_phase7a_record('NX4-base', scene_preset, SBase);
records_cell{2} = local_pack_phase7a_record('NX4-soft', scene_preset, SSoft);
records_cell{3} = local_pack_proposal_only_record('NX4-proposal-only', scene_preset, proposalOnly);
records = [records_cell{:}];

if verbose
    disp('=== NX-4 soft compare ===')
    disp(struct2table(records))
end

out = struct();
out.records = records;
out.outBase = outBase;
out.outSoft = outSoft;
out.proposalOnly = proposalOnly;
end

function cfg = local_make_cfg(scene_preset, use_soft)
cfg = default_ch5_params(scene_preset);
cfg = apply_nx2_state_machine_defaults(cfg);
cfg = apply_nx3_guard_defaults(cfg);
cfg = apply_nx3_guard_action_defaults(cfg);
cfg = apply_nx4_proposal_defaults(cfg);
cfg = apply_nx4_soft_defaults(cfg);

cfg.ch5.nx2_dwell_steps = 16;
cfg.ch5.nx3_guard_enable = true;
cfg.ch5.nx3_guard_action_mode = 'none';
cfg.ch5.nx4_soft_enable = use_soft;
end

function r = local_pack_phase7a_record(name, scene_preset, S)
r = struct();
r.name = string(name);
r.scene_preset = string(scene_preset);
r.q_worst_window = S.custodyCK.q_worst_window;
r.outage_ratio = S.custodyCK.outage_ratio;
r.longest_outage_steps = S.custodyCK.longest_outage_steps;
r.mean_rmse = S.trackingStatsCK.mean_rmse;
r.switch_count = local_count_switches(S.trackingCK);
r.applied_switch_count = local_count_applied_switches(S.trackingCK);
r.overlap_top1 = NaN;
r.overlap_topk = NaN;
end

function r = local_pack_proposal_only_record(name, scene_preset, proposalOnly)
r = struct();
r.name = string(name);
r.scene_preset = string(scene_preset);
r.q_worst_window = NaN;
r.outage_ratio = NaN;
r.longest_outage_steps = NaN;
r.mean_rmse = NaN;
r.switch_count = NaN;
r.applied_switch_count = NaN;
r.overlap_top1 = proposalOnly.overlap_top1;
r.overlap_topk = proposalOnly.overlap_topk;
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
