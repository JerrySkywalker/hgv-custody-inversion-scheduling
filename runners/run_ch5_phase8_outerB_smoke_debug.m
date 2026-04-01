function out = run_ch5_phase8_outerB_smoke_debug()
% 最小 outerB smoke debug
%
% 目标：
% 1) 找到一个最小可运行 caseData/cfg
% 2) 调一次 select_satellite_set_custody_dualloop
% 3) 同时单独调一次 build_window_objective_dualloop
% 4) 导出 detail 供检查 continuous prior 是否接入成功

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase8_outerB_smoke');
if ~exist(out_root, 'dir'); mkdir(out_root); end

cfg = default_ch5_params();
cfg.ch5.continuous_prior_enable = true;
cfg.ch5.continuous_prior_mode = 'ck_plus_full_prior';

% ----------------------------
% 尝试复用现有最小场景构造函数
% 这里优先走你现有 ch5 工程默认入口
% ----------------------------
assert(exist('build_case_data_ch5', 'file') == 2 || exist('make_case_data_ch5', 'file') == 2 || exist('package_inner_loop_result', 'file') == 2, ...
    'Could not find known case-data builder functions on path.');

caseData = [];
builder_used = "";

if exist('build_case_data_ch5', 'file') == 2
    caseData = build_case_data_ch5(cfg);
    builder_used = "build_case_data_ch5";
elseif exist('make_case_data_ch5', 'file') == 2
    caseData = make_case_data_ch5(cfg);
    builder_used = "make_case_data_ch5";
else
    error('No direct caseData builder found. Please inspect existing minimal phase runner.');
end

assert(~isempty(caseData), 'caseData is empty after builder call.');

k = 1;
prev_ids = [];
mode = 'warn';

if isfield(caseData, 'candidates') && isfield(caseData.candidates, 'visible_mask')
    N = size(caseData.candidates.visible_mask, 1);
    if N >= 2
        k = 2;
    end
end

selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg);

ref_ids = [];
if isfield(cfg.ch5, 'prior_enable') && cfg.ch5.prior_enable && isfield(cfg.ch5, 'prior_library') && ~isempty(cfg.ch5.prior_library)
    ref_ids = match_reference_prior(cfg.ch5.prior_library, caseData, k, prev_ids, cfg);
elseif exist('select_reference_template_dualloop', 'file') == 2
    ref_ids = select_reference_template_dualloop(caseData, k, cfg);
end

[score, detail] = build_window_objective_dualloop(mode, selected_ids, prev_ids, ref_ids, caseData, k, cfg);

txt_path = fullfile(out_root, 'phase8_outerB_smoke_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Phase08 outerB smoke debug summary ===\n');
fprintf(fid, 'builder_used = %s\n', builder_used);
fprintf(fid, 'k = %d\n', k);
fprintf(fid, 'mode = %s\n', mode);
fprintf(fid, 'selected_ids = ');
fprintf(fid, '%d ', selected_ids);
fprintf(fid, '\n');
fprintf(fid, 'score = %.12f\n', score);
fprintf(fid, '\n');

detail_fields = fieldnames(detail);
fprintf(fid, '--- detail fields ---\n');
for i = 1:numel(detail_fields)
    fn = detail_fields{i};
    val = detail.(fn);
    if isnumeric(val) && isscalar(val)
        fprintf(fid, '%s = %.12f\n', fn, val);
    elseif isstring(val) || ischar(val)
        fprintf(fid, '%s = %s\n', fn, string(val));
    end
end
fclose(fid);

mat_path = fullfile(out_root, 'phase8_outerB_smoke_result.mat');
save(mat_path, 'cfg', 'caseData', 'k', 'mode', 'selected_ids', 'ref_ids', 'score', 'detail', 'builder_used');

disp('=== Phase08 outerB smoke debug ===');
disp(['[phase8-outerB] text : ', txt_path]);
disp(['[phase8-outerB] mat  : ', mat_path]);

out = struct();
out.summary_file = txt_path;
out.mat_file = mat_path;
out.output_root = out_root;
end
