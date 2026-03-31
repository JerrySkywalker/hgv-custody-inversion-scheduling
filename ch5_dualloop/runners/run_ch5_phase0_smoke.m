function out = run_ch5_phase0_smoke(cfg, verbose)
%RUN_CH5_PHASE0_SMOKE  Phase 0 smoke runner for chapter 5 isolated workspace.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2
    verbose = true;
end

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase0');
log_dir = fullfile(out_root, 'logs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');

if ~exist(log_dir, 'dir'); mkdir(log_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

caseData = build_ch5_case(cfg);
lines = summarize_ch5_case(caseData);

txt_path = fullfile(tbl_dir, 'case_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary text file for writing: %s', txt_path);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end

log_path = fullfile(log_dir, 'phase0_smoke_log.txt');
fid2 = fopen(log_path, 'w');
assert(fid2 >= 0, 'Failed to open log file for writing: %s', log_path);
cleanupObj2 = onCleanup(@() fclose(fid2)); %#ok<NASGU>
fprintf(fid2, '[INFO] run_ch5_phase0_smoke started\n');
fprintf(fid2, '[INFO] output_root = %s\n', out_root);
fprintf(fid2, '[INFO] num_steps = %d\n', caseData.summary.num_steps);
fprintf(fid2, '[INFO] num_sats = %d\n', caseData.summary.num_sats);
fprintf(fid2, '[INFO] candidate_count_min = %.0f\n', caseData.summary.min_candidate_count);
fprintf(fid2, '[INFO] candidate_count_max = %.0f\n', caseData.summary.max_candidate_count);
fprintf(fid2, '[INFO] candidate_count_mean = %.3f\n', caseData.summary.mean_candidate_count);
fprintf(fid2, '[INFO] run_ch5_phase0_smoke finished\n');

mat_path = fullfile(mat_dir, 'case_summary.mat');
save(mat_path, 'cfg', 'caseData', 'lines');

if verbose
    for i = 1:numel(lines)
        disp(lines{i});
    end
    disp(['[phase0] summary text: ', txt_path]);
    disp(['[phase0] log file    : ', log_path]);
    disp(['[phase0] mat file    : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.caseData = caseData;
end
