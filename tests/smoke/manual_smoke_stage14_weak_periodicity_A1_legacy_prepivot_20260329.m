function out = manual_smoke_stage14_weak_periodicity_A1_legacy_prepivot_20260329(cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%MANUAL_SMOKE_STAGE14_WEAK_PERIODICITY_A1_LEGACY_PREPIVOT_20260329
% Stage14 旧版探索归档（原 Stage14.2C）:
% 对 A1 案例做更细 RAAN 扫描，并检查弱周期/近周期特征。
%
% A1:
%   h=1000, i=40, P=8, T=6, F=1, Ns=48
%
% 输出：
%   out.detail_table
%   out.summary
%   out.delta45
%   out.delta90
%   out.delta180

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    if ~isfield(overrides, 'RAAN_scan_deg')
        overrides.RAAN_scan_deg = 0:15:345;
    end
    if ~isfield(overrides, 'case_limit')
        overrides.case_limit = inf;
    end
    if ~isfield(overrides, 'use_early_stop')
        overrides.use_early_stop = false;
    end
    if ~isfield(overrides, 'hard_case_first')
        overrides.hard_case_first = true;
    end
    if ~isfield(overrides, 'require_pass_ratio')
        overrides.require_pass_ratio = 1.0;
    end
    if ~isfield(overrides, 'require_D_G_min')
        overrides.require_D_G_min = 1.0;
    end

    local_overrides = struct();
    local_overrides.h_fixed_km = 1000;
    local_overrides.i_grid_deg = 40;
    local_overrides.P_grid = 8;
    local_overrides.T_grid = 6;
    local_overrides.F_fixed = 1;
    local_overrides.RAAN_scan_deg = overrides.RAAN_scan_deg;
    local_overrides.case_limit = overrides.case_limit;
    local_overrides.use_early_stop = overrides.use_early_stop;
    local_overrides.hard_case_first = overrides.hard_case_first;
    local_overrides.require_pass_ratio = overrides.require_pass_ratio;
    local_overrides.require_D_G_min = overrides.require_D_G_min;

    sweep_out = manual_smoke_stage14_raan_sweep(cfg, local_overrides);
    T = sweep_out.table;
    T = sortrows(T, 'RAAN_deg');

    delta45 = local_build_delta_table(T, 45);
    delta90 = local_build_delta_table(T, 90);
    delta180 = local_build_delta_table(T, 180);

    summary = struct();
    summary.case_count = sweep_out.summary.case_count;
    summary.RAAN_scan_deg = overrides.RAAN_scan_deg;
    summary.pass_ratio_span = max(T.pass_ratio) - min(T.pass_ratio);
    summary.D_G_mean_span = max(T.D_G_mean) - min(T.D_G_mean);
    summary.D_G_min_span = max(T.D_G_min) - min(T.D_G_min);

    summary.max_abs_delta45_pass_ratio = max(abs(delta45.pass_ratio_delta), [], 'omitnan');
    summary.max_abs_delta45_D_G_mean = max(abs(delta45.D_G_mean_delta), [], 'omitnan');
    summary.max_abs_delta45_D_G_min = max(abs(delta45.D_G_min_delta), [], 'omitnan');

    summary.max_abs_delta90_pass_ratio = max(abs(delta90.pass_ratio_delta), [], 'omitnan');
    summary.max_abs_delta90_D_G_mean = max(abs(delta90.D_G_mean_delta), [], 'omitnan');
    summary.max_abs_delta90_D_G_min = max(abs(delta90.D_G_min_delta), [], 'omitnan');

    summary.max_abs_delta180_pass_ratio = max(abs(delta180.pass_ratio_delta), [], 'omitnan');
    summary.max_abs_delta180_D_G_mean = max(abs(delta180.D_G_mean_delta), [], 'omitnan');
    summary.max_abs_delta180_D_G_min = max(abs(delta180.D_G_min_delta), [], 'omitnan');

    out = struct();
    out.detail_table = T;
    out.summary = summary;
    out.delta45 = delta45;
    out.delta90 = delta90;
    out.delta180 = delta180;

    fprintf('\n=== Stage14 旧版探索归档（原 Stage14.2C） Weak Periodicity Check: A1 ===\n');
    fprintf('RAAN_scan_deg                 : %s\n', mat2str(summary.RAAN_scan_deg));
    fprintf('case_count                    : %d\n', summary.case_count);
    fprintf('pass_ratio span               : %.12g\n', summary.pass_ratio_span);
    fprintf('D_G_mean span                 : %.12g\n', summary.D_G_mean_span);
    fprintf('D_G_min span                  : %.12g\n', summary.D_G_min_span);
    fprintf('\n');
    fprintf('max |Δ45|  pass_ratio         : %.12g\n', summary.max_abs_delta45_pass_ratio);
    fprintf('max |Δ45|  D_G_mean           : %.12g\n', summary.max_abs_delta45_D_G_mean);
    fprintf('max |Δ45|  D_G_min            : %.12g\n', summary.max_abs_delta45_D_G_min);
    fprintf('\n');
    fprintf('max |Δ90|  pass_ratio         : %.12g\n', summary.max_abs_delta90_pass_ratio);
    fprintf('max |Δ90|  D_G_mean           : %.12g\n', summary.max_abs_delta90_D_G_mean);
    fprintf('max |Δ90|  D_G_min            : %.12g\n', summary.max_abs_delta90_D_G_min);
    fprintf('\n');
    fprintf('max |Δ180| pass_ratio         : %.12g\n', summary.max_abs_delta180_pass_ratio);
    fprintf('max |Δ180| D_G_mean           : %.12g\n', summary.max_abs_delta180_D_G_mean);
    fprintf('max |Δ180| D_G_min            : %.12g\n\n', summary.max_abs_delta180_D_G_min);

    fprintf('--- detail_table (head) ---\n');
    disp(T(1:min(24,height(T)), {'RAAN_deg','D_G_min','D_G_mean','pass_ratio'}));

    fprintf('--- delta45 (head) ---\n');
    disp(delta45(1:min(12,height(delta45)), :));

    fprintf('--- delta90 (head) ---\n');
    disp(delta90(1:min(12,height(delta90)), :));

    fprintf('--- delta180 (head) ---\n');
    disp(delta180(1:min(12,height(delta180)), :));
end

function D = local_build_delta_table(T, shift_deg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
    raan = T.RAAN_deg(:);
    D = table();
    D.RAAN_deg = raan;
    D.shift_deg = repmat(shift_deg, numel(raan), 1);
    D.RAAN_shifted_deg = mod(raan + shift_deg, 360);

    D.pass_ratio = T.pass_ratio(:);
    D.D_G_mean = T.D_G_mean(:);
    D.D_G_min = T.D_G_min(:);

    D.pass_ratio_shifted = nan(numel(raan),1);
    D.D_G_mean_shifted = nan(numel(raan),1);
    D.D_G_min_shifted = nan(numel(raan),1);

    for k = 1:numel(raan)
        idx = find(raan == D.RAAN_shifted_deg(k), 1);
        if ~isempty(idx)
            D.pass_ratio_shifted(k) = T.pass_ratio(idx);
            D.D_G_mean_shifted(k) = T.D_G_mean(idx);
            D.D_G_min_shifted(k) = T.D_G_min(idx);
        end
    end

    D.pass_ratio_delta = D.pass_ratio_shifted - D.pass_ratio;
    D.D_G_mean_delta = D.D_G_mean_shifted - D.D_G_mean;
    D.D_G_min_delta = D.D_G_min_shifted - D.D_G_min;
end

