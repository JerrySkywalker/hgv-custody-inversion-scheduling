function out = manual_smoke_stage14_A1_formal_package(out14FR, out14FR_post, cfg, overrides)
%MANUAL_SMOKE_STAGE14_A1_FORMAL_PACKAGE
% 方案 A：整理 A1 的正式图表与章节口径
%
% 输入：
%   out14FR      : manual_smoke_stage14_F_RAAN_grid_A1 输出
%   out14FR_post : manual_smoke_stage14_F_RAAN_postprocess_A1 输出
%
% 输出：
%   1) summary tables (csv)
%   2) formal markdown summary
%   3) packaged file paths

    if nargin < 1 || isempty(out14FR)
        error('out14FR is required.');
    end
    if nargin < 2 || isempty(out14FR_post)
        error('out14FR_post is required.');
    end
    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 4 || isempty(overrides)
        overrides = struct();
    end

    cfg.project_stage = 'stage14_A1_formal_package';
    cfg = configure_stage_output_paths(cfg);

    % 关键修正：
    % cfg.paths.stage_figs 已经正确落在 outputs/stage/stage14/figs
    % 这里取其上一级，确保表和 markdown 落在 outputs/stage/stage14
    fig_dir = cfg.paths.stage_figs;
    out_dir = fileparts(fig_dir);

    if ~exist(out_dir, 'dir'); mkdir(out_dir); end
    if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

    ts = datestr(now, 'yyyymmdd_HHMMSS');

    bestF_table = out14FR_post.bestF_table;
    robust_stats_table = out14FR_post.robust_stats_table;
    periodicity_F0 = out14FR_post.periodicity_F0;

    % ------------------------------------------------------------
    % 1) 提炼正式摘要表
    % ------------------------------------------------------------
    [~, idx_best_pass_mean] = max(robust_stats_table.pass_ratio_mean);
    [~, idx_best_dgm_mean] = max(robust_stats_table.DG_mean_mean);
    [~, idx_best_dgmin_mean] = max(robust_stats_table.DG_min_mean);

    F_values = robust_stats_table.F;
    bestF_dgmin_counts = zeros(size(F_values));
    for k = 1:numel(F_values)
        bestF_dgmin_counts(k) = sum(bestF_table.bestF_DG_min == F_values(k));
    end

    key_summary = table( ...
        string("best_mean_pass_ratio"), robust_stats_table.F(idx_best_pass_mean), robust_stats_table.pass_ratio_mean(idx_best_pass_mean), ...
        string("best_mean_DG_mean"),    robust_stats_table.F(idx_best_dgm_mean), robust_stats_table.DG_mean_mean(idx_best_dgm_mean), ...
        string("best_mean_DG_min"),     robust_stats_table.F(idx_best_dgmin_mean), robust_stats_table.DG_min_mean(idx_best_dgmin_mean), ...
        'VariableNames', {'metric1','F1','value1','metric2','F2','value2','metric3','F3','value3'});

    dgmin_switch_table = table(F_values, bestF_dgmin_counts, ...
        'VariableNames', {'F','bestF_DG_min_count_over_RAAN'});

    % ------------------------------------------------------------
    % 2) 生成 markdown 正式摘要
    % ------------------------------------------------------------
    md_lines = {};
    md_lines{end+1} = '# Stage14 A1 正式结果摘要';
    md_lines{end+1} = '';
    md_lines{end+1} = '## 1. 实验对象';
    md_lines{end+1} = '- 构型：A1, h=1000 km, i=40 deg, P=8, T=6, Ns=48';
    md_lines{end+1} = '- 扫描变量：F = 0:7, RAAN = 0:15:345';
    md_lines{end+1} = '- 指标：D_G_min, D_G_mean, pass_ratio';
    md_lines{end+1} = '';
    md_lines{end+1} = '## 2. 核心结论';
    md_lines{end+1} = sprintf('- 平均表现最优相位：F=%d（pass_ratio_mean=%.6f, DG_mean_mean=%.6f）', ...
        robust_stats_table.F(idx_best_pass_mean), ...
        robust_stats_table.pass_ratio_mean(idx_best_pass_mean), ...
        robust_stats_table.DG_mean_mean(idx_best_dgm_mean));
    md_lines{end+1} = sprintf('- 最坏-case 平均最优相位：F=%d（DG_min_mean=%.6f）', ...
        robust_stats_table.F(idx_best_dgmin_mean), ...
        robust_stats_table.DG_min_mean(idx_best_dgmin_mean));
    md_lines{end+1} = '- D_G_min 的最优 F 随 RAAN 切换，不存在唯一全局最优相位。';
    md_lines{end+1} = '- F=0 在 45/90/180 度位移下呈现严格重复，可作为对称基准态。';
    md_lines{end+1} = '';
    md_lines{end+1} = '## 3. F=0 对称基准态摘要';
    md_lines{end+1} = sprintf('- pass_ratio: max|Δ45|=%.6g, max|Δ90|=%.6g, max|Δ180|=%.6g, max|Δ30|=%.6g', ...
        periodicity_F0.pass_ratio.max_abs_delta45, ...
        periodicity_F0.pass_ratio.max_abs_delta90, ...
        periodicity_F0.pass_ratio.max_abs_delta180, ...
        periodicity_F0.pass_ratio.max_abs_delta30);
    md_lines{end+1} = sprintf('- DG_mean:   max|Δ45|=%.6g, max|Δ90|=%.6g, max|Δ180|=%.6g, max|Δ30|=%.6g', ...
        periodicity_F0.DG_mean.max_abs_delta45, ...
        periodicity_F0.DG_mean.max_abs_delta90, ...
        periodicity_F0.DG_mean.max_abs_delta180, ...
        periodicity_F0.DG_mean.max_abs_delta30);
    md_lines{end+1} = sprintf('- DG_min:    max|Δ45|=%.6g, max|Δ90|=%.6g, max|Δ180|=%.6g, max|Δ30|=%.6g', ...
        periodicity_F0.DG_min.max_abs_delta45, ...
        periodicity_F0.DG_min.max_abs_delta90, ...
        periodicity_F0.DG_min.max_abs_delta180, ...
        periodicity_F0.DG_min.max_abs_delta30);
    md_lines{end+1} = '';
    md_lines{end+1} = '## 4. 章节口径建议';
    md_lines{end+1} = '- 将 A1 作为 Stage14 主案例。';
    md_lines{end+1} = '- 先展示单参数切片图，再展示 (F,RAAN) 热图。';
    md_lines{end+1} = '- 之后用 bestF_by_RAAN 和 robust_stats_by_F 解释“平均最优相位”与“最坏-case 局部优相位”的分裂。';
    md_lines{end+1} = '- 将 F=0 单独作为对称基准态进行说明。';

    md_text = strjoin(md_lines, newline);

    % ------------------------------------------------------------
    % 3) 保存文件
    % ------------------------------------------------------------
    files = struct();
    files.out_dir = out_dir;
    files.bestF_csv = fullfile(out_dir, sprintf('stage14_A1_bestF_table_%s.csv', ts));
    files.robust_stats_csv = fullfile(out_dir, sprintf('stage14_A1_robust_stats_%s.csv', ts));
    files.dgmin_switch_csv = fullfile(out_dir, sprintf('stage14_A1_bestF_DGmin_counts_%s.csv', ts));
    files.key_summary_csv = fullfile(out_dir, sprintf('stage14_A1_key_summary_%s.csv', ts));
    files.formal_md = fullfile(out_dir, sprintf('stage14_A1_formal_summary_%s.md', ts));

    writetable(bestF_table, files.bestF_csv);
    writetable(robust_stats_table, files.robust_stats_csv);
    writetable(dgmin_switch_table, files.dgmin_switch_csv);
    writetable(key_summary, files.key_summary_csv);

    fid = fopen(files.formal_md, 'w');
    assert(fid > 0, 'Failed to open markdown output file.');
    fprintf(fid, '%s\n', md_text);
    fclose(fid);

    out = struct();
    out.bestF_table = bestF_table;
    out.robust_stats_table = robust_stats_table;
    out.dgmin_switch_table = dgmin_switch_table;
    out.key_summary = key_summary;
    out.formal_md_text = md_text;
    out.files = files;

    fprintf('\n=== Stage14 A1 Formal Package ===\n');
    fprintf('output dir         : %s\n', files.out_dir);
    fprintf('bestF csv          : %s\n', files.bestF_csv);
    fprintf('robust stats csv   : %s\n', files.robust_stats_csv);
    fprintf('DGmin switch csv   : %s\n', files.dgmin_switch_csv);
    fprintf('key summary csv    : %s\n', files.key_summary_csv);
    fprintf('formal markdown    : %s\n\n', files.formal_md);

    fprintf('--- key_summary ---\n');
    disp(key_summary);

    fprintf('--- dgmin_switch_table ---\n');
    disp(dgmin_switch_table);

    fprintf('--- markdown preview ---\n');
    fprintf('%s\n', md_text);
end
