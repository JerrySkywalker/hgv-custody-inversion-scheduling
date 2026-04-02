function out = run_nx4_proposal_compare_smoke(scene_preset, k, verbose)
%RUN_NX4_PROPOSAL_COMPARE_SMOKE
% NX-4 first round
% Compare baseline CK selection vs proposal layer at one snapshot.

if nargin < 1 || isempty(scene_preset)
    scene_preset = 'ref128';
end
if nargin < 2 || isempty(k)
    k = 10;
end
if nargin < 3
    verbose = true;
end

cfg = default_ch5_params(scene_preset);
cfg = apply_nx2_state_machine_defaults(cfg);
cfg = apply_nx3_guard_defaults(cfg);
cfg = apply_nx3_guard_action_defaults(cfg);
cfg = apply_nx4_proposal_defaults(cfg);

cfg.ch5.nx2_dwell_steps = 16;
cfg.ch5.nx3_guard_enable = true;
cfg.ch5.nx3_guard_action_mode = 'none';

caseData = build_ch5_case(cfg);

outerA_out = run_ch5_phase6_outerA_rfkoopman(cfg, false);
OA = load(outerA_out.mat_file);
risk_state_now = OA.outerA.risk_state(k);
mode = dispatch_quadrant_policy(risk_state_now);

baseline_ids = select_satellite_set_custody_dualloop(caseData, k, [], char(mode), cfg);

proposal = build_nx4_template_proposal(caseData, k, cfg);

top_pair = [];
overlap_top1 = 0;
overlap_topk = 0;

if ~isempty(proposal.proposal_pairs)
    top_pair = proposal.proposal_pairs(1,:);
    overlap_top1 = numel(intersect(baseline_ids(:).', top_pair(:).')) / max(1, numel(union(baseline_ids(:).', top_pair(:).')));
    overlap_topk = local_overlap_topk(baseline_ids, proposal.proposal_pairs);
end

out_root = fullfile(pwd, 'outputs', 'cpt5', 'nx4_proposal_compare', scene_preset);
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

txt_path = fullfile(tbl_dir, sprintf('nx4_proposal_compare_%s_k%04d.txt', scene_preset, k));
mat_path = fullfile(mat_dir, sprintf('nx4_proposal_compare_%s_k%04d.mat', scene_preset, k));
local_write_summary(txt_path, scene_preset, k, mode, baseline_ids, proposal, overlap_top1, overlap_topk);
save(mat_path, 'scene_preset', 'k', 'mode', 'baseline_ids', 'proposal', 'overlap_top1', 'overlap_topk');

if verbose
    disp('=== NX-4 proposal compare smoke ===')
    disp(struct( ...
        'scene_preset', scene_preset, ...
        'k', k, ...
        'mode', string(mode), ...
        'baseline_ids', baseline_ids, ...
        'top_pair', top_pair, ...
        'overlap_top1', overlap_top1, ...
        'overlap_topk', overlap_topk))
    disp(txt_path)
    disp(mat_path)
end

out = struct();
out.scene_preset = string(scene_preset);
out.k = k;
out.mode = string(mode);
out.baseline_ids = baseline_ids;
out.proposal = proposal;
out.overlap_top1 = overlap_top1;
out.overlap_topk = overlap_topk;
out.text_file = txt_path;
out.mat_file = mat_path;
end

function overlap = local_overlap_topk(baseline_ids, proposal_pairs)
if isempty(proposal_pairs)
    overlap = 0;
    return
end
cand = unique(proposal_pairs(:).', 'stable');
overlap = numel(intersect(baseline_ids(:).', cand)) / max(1, numel(union(baseline_ids(:).', cand)));
end

function local_write_summary(pathStr, scene_preset, k, mode, baseline_ids, proposal, overlap_top1, overlap_topk)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== NX-4 proposal compare smoke ===\n');
fprintf(fid, 'scene_preset = %s\n', scene_preset);
fprintf(fid, 'k = %d\n', k);
fprintf(fid, 'mode = %s\n\n', char(mode));

fprintf(fid, 'baseline_ids = [%s]\n', sprintf('%g ', baseline_ids));
fprintf(fid, 'reference_k = %d\n', proposal.reference_k);
fprintf(fid, 'reference_visible_ids = [%s]\n', sprintf('%g ', proposal.reference_visible_ids));
fprintf(fid, 'current_visible_ids = [%s]\n', sprintf('%g ', proposal.current_visible_ids));
fprintf(fid, 'match.best_template_id = %s\n', char(proposal.match.best_template_id));
fprintf(fid, 'match.best_template_family = %s\n', char(proposal.match.best_template_family));
fprintf(fid, 'match.best_distance = %.6f\n', proposal.match.best_distance);
fprintf(fid, 'overlap_top1 = %.6f\n', overlap_top1);
fprintf(fid, 'overlap_topk = %.6f\n\n', overlap_topk);

fprintf(fid, 'proposal_pairs:\n');
for i = 1:size(proposal.proposal_pairs,1)
    fprintf(fid, '[%g %g] score=%.6f\n', proposal.proposal_pairs(i,1), proposal.proposal_pairs(i,2), proposal.proposal_scores(i));
end
end
