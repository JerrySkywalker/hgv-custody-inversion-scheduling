function out = run_ch5_phase7A_select_debug(cfg, verbose)
%RUN_CH5_PHASE7A_SELECT_DEBUG
% Diagnose where C and CK choose different satellite sets.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase7a_select_dbg');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);

trackingC = policy_custody_singleloop(caseData, cfg);
trackingCK = policy_custody_dualloop_koopman(caseData, cfg);

cmp = compare_selected_sets_dualloop(trackingC, trackingCK);

% sample first up to 8 differing steps
max_dump = 8;
dump_idx = cmp.diff_idx(1:min(max_dump, numel(cmp.diff_idx)));

dumpTables = struct();

for ii = 1:numel(dump_idx)
    k = dump_idx(ii);

    % reconstruct CK mode at this step
    rs = trackingCK.outerA.risk_state(k);
    mode = dispatch_quadrant_policy(rs);

    if k > 1
        prev_ids = trackingCK.selected_sets{k-1};
    else
        prev_ids = [];
    end

    rows = dump_candidate_scores_dualloop(caseData, k, prev_ids, mode, cfg);
    dumpTables(ii).k = k;
    dumpTables(ii).mode = string(mode);
    dumpTables(ii).selected_C = trackingC.selected_sets{k};
    dumpTables(ii).selected_CK = trackingCK.selected_sets{k};
    dumpTables(ii).rows = rows;

    txt_step = fullfile(tbl_dir, sprintf('phase7a_select_dbg_step_%s_k%04d.txt', cfg.ch5.scene_preset, k));
    local_write_step_table(txt_step, dumpTables(ii));
end

summary_path = fullfile(tbl_dir, ['phase7a_select_dbg_summary_', cfg.ch5.scene_preset, '.txt']);
summary_lines = {
    '=== Chapter 5 Phase 7A-select-dbg Summary ==='
    ['scene_preset              = ', cfg.ch5.scene_preset]
    ['num_steps                 = ', num2str(cmp.num_steps)]
    ['same_ratio                = ', num2str(cmp.same_ratio, '%.6f')]
    ['diff_count                = ', num2str(cmp.diff_count)]
    ['dumped_steps              = ', num2str(numel(dump_idx))]
    };
local_write_txt(summary_path, summary_lines);

log_path = fullfile(log_dir, ['phase7a_select_dbg_log_', cfg.ch5.scene_preset, '.txt']);
local_write_txt(log_path, summary_lines);

mat_path = fullfile(mat_dir, ['phase7a_select_dbg_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'caseData', 'trackingC', 'trackingCK', 'cmp', 'dumpTables');

if verbose
    disp('=== Chapter 5 Phase 7A-select-dbg Summary ===')
    disp(cmp)
    disp(['[phase7a-select-dbg] summary : ', summary_path])
    disp(['[phase7a-select-dbg] log     : ', log_path])
    disp(['[phase7a-select-dbg] mat     : ', mat_path])
end

out = struct();
out.summary_file = summary_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.dump_idx = dump_idx;
end

function local_write_txt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end

function local_write_step_table(pathStr, tab)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Phase 7A-select-dbg Step Dump ===\n');
fprintf(fid, 'k = %d\n', tab.k);
fprintf(fid, 'mode = %s\n', tab.mode);
fprintf(fid, 'selected_C = [%s]\n', num2str(tab.selected_C));
fprintf(fid, 'selected_CK = [%s]\n', num2str(tab.selected_CK));
fprintf(fid, '\n');

fprintf(fid, 'ids\tfeasible\tlongest_single\tsingle_ratio\tzero_ratio\tscore\n');
for i = 1:numel(tab.rows)
    r = tab.rows(i);
    fprintf(fid, '[%s]\t%d\t%d\t%.6f\t%.6f\t%.6f\n', ...
        num2str(r.ids), r.is_feasible, r.longest_single, r.single_ratio, r.zero_ratio, r.score);
end
end
