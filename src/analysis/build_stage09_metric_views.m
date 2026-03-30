function views = build_stage09_metric_views(out, mode_tag)
%BUILD_STAGE09_METRIC_VIEWS
% Build standardized metric views from Stage09 full_theta_table.
%
% Inputs
%   out      : struct with out.s4.full_theta_table and out.s4.cfg
%   mode_tag : optional suffix for exported files
%
% Outputs
%   views.DG.table
%   views.DA.table
%   views.DT.table
%   views.joint.table
%   views.summary

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase1';
    end

    if ~isfield(out, 's4') || ~isfield(out.s4, 'full_theta_table') || ~istable(out.s4.full_theta_table)
        error('build_stage09_metric_views:MissingFullTable', ...
            'out.s4.full_theta_table is required.');
    end
    if ~isfield(out.s4, 'cfg') || ~isstruct(out.s4.cfg)
        error('build_stage09_metric_views:MissingCfg', ...
            'out.s4.cfg is required.');
    end

    T = out.s4.full_theta_table;
    cfg = out.s4.cfg;

    required_vars = {'h_km','i_deg','P','T','F','Ns','DG_rob','DA_rob','DT_rob','pass_ratio','joint_margin','dominant_fail_tag'};
    missing = required_vars(~ismember(required_vars, T.Properties.VariableNames));
    if ~isempty(missing)
        error('build_stage09_metric_views:MissingVars', ...
            'Missing required variables: %s', strjoin(missing, ', '));
    end

    reqDG = cfg.stage09.require_DG_min;
    reqDA = cfg.stage09.require_DA_min;
    reqDT = cfg.stage09.require_DT_min;
    reqPR = cfg.stage09.require_pass_ratio;

    tables_dir = cfg.paths.tables;
    if ~exist(tables_dir, 'dir')
        mkdir(tables_dir);
    end
    run_tag = char(string(cfg.stage09.run_tag));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    base_cols = {'h_km','i_deg','P','T','F','Ns','DG_rob','DA_rob','DT_rob','pass_ratio','joint_margin','dominant_fail_tag'};
    if ismember('feasible_stage05_compat', T.Properties.VariableNames)
        base_cols{end+1} = 'feasible_stage05_compat';
    end
    if ismember('joint_feasible', T.Properties.VariableNames)
        base_cols{end+1} = 'joint_feasible';
    end

    Vdg = local_make_metric_view(T(:, base_cols), 'DG', 'DG_rob', reqDG, reqPR);
    Vda = local_make_metric_view(T(:, base_cols), 'DA', 'DA_rob', reqDA, reqPR);
    Vdt = local_make_metric_view(T(:, base_cols), 'DT', 'DT_rob', reqDT, reqPR);
    Vjt = local_make_joint_view(T(:, base_cols), reqDG, reqDA, reqDT, reqPR);

    dg_csv = fullfile(tables_dir, sprintf('stage09_metric_view_DG_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    da_csv = fullfile(tables_dir, sprintf('stage09_metric_view_DA_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    dt_csv = fullfile(tables_dir, sprintf('stage09_metric_view_DT_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    jt_csv = fullfile(tables_dir, sprintf('stage09_metric_view_joint_%s_%s_%s.csv', run_tag, mode_tag, timestamp));

    writetable(Vdg, dg_csv);
    writetable(Vda, da_csv);
    writetable(Vdt, dt_csv);
    writetable(Vjt, jt_csv);

    summary = table( ...
        ["DG";"DA";"DT";"joint"], ...
        [reqDG;reqDA;reqDT;NaN], ...
        [sum(Vdg.metric_pass); sum(Vda.metric_pass); sum(Vdt.metric_pass); NaN], ...
        [sum(Vdg.pass_PR); sum(Vda.pass_PR); sum(Vdt.pass_PR); sum(Vjt.pass_PR)], ...
        [sum(Vdg.feasible_flag); sum(Vda.feasible_flag); sum(Vdt.feasible_flag); sum(Vjt.feasible_flag)], ...
        [local_min_or_nan(Vdg.Ns(Vdg.feasible_flag)); ...
         local_min_or_nan(Vda.Ns(Vda.feasible_flag)); ...
         local_min_or_nan(Vdt.Ns(Vdt.feasible_flag)); ...
         local_min_or_nan(Vjt.Ns(Vjt.feasible_flag))], ...
        [local_min_positive_or_nan(Vdg.metric_value); ...
         local_min_positive_or_nan(Vda.metric_value); ...
         local_min_positive_or_nan(Vdt.metric_value); ...
         local_min_positive_or_nan(Vjt.metric_value)], ...
        [max(Vdg.metric_value); max(Vda.metric_value); max(Vdt.metric_value); max(Vjt.metric_value)], ...
        'VariableNames', {'metric_name','metric_threshold','n_metric_pass','n_pass_ratio','n_feasible','Ns_min_feasible','metric_min_positive','metric_max_value'});

    fprintf('\n');
    fprintf('=========== Stage09 Metric Views (Phase1-B) ===========\n');
    fprintf('run_tag            : %s\n', run_tag);
    fprintf('mode_tag           : %s\n', mode_tag);
    fprintf('DG view CSV        : %s\n', dg_csv);
    fprintf('DA view CSV        : %s\n', da_csv);
    fprintf('DT view CSV        : %s\n', dt_csv);
    fprintf('joint view CSV     : %s\n', jt_csv);
    disp(summary);
    fprintf('=======================================================\n\n');

    views = struct();
    views.DG = struct('table', Vdg, 'csv', dg_csv);
    views.DA = struct('table', Vda, 'csv', da_csv);
    views.DT = struct('table', Vdt, 'csv', dt_csv);
    views.joint = struct('table', Vjt, 'csv', jt_csv);
    views.summary = summary;
end


function V = local_make_metric_view(T, metric_name, metric_col, threshold, pass_ratio_threshold)

    V = T;
    V.metric_name = repmat(string(metric_name), height(V), 1);
    V.metric_value = V.(metric_col);
    V.metric_threshold = repmat(threshold, height(V), 1);
    V.metric_margin = V.metric_value - threshold;
    V.metric_pass = isfinite(V.metric_value) & (V.metric_value >= threshold);
    V.pass_PR = isfinite(V.pass_ratio) & (V.pass_ratio >= pass_ratio_threshold);
    V.feasible_flag = V.metric_pass & V.pass_PR;

    V.metric_value_clipped = max(V.metric_value, 0);
    V.metric_value_log10 = local_safe_log10(V.metric_value_clipped);
    V.is_transition_candidate = V.metric_pass | V.pass_PR | V.feasible_flag;
    V.is_pareto_candidate = V.feasible_flag;

    V = movevars(V, {'metric_name','metric_value','metric_threshold','metric_margin','metric_pass','pass_PR','feasible_flag','metric_value_clipped','metric_value_log10','is_transition_candidate','is_pareto_candidate'}, 'After', 'Ns');
end


function V = local_make_joint_view(T, reqDG, reqDA, reqDT, pass_ratio_threshold)

    V = T;
    V.metric_name = repmat("joint", height(V), 1);
    V.metric_value = V.joint_margin;
    V.metric_threshold = repmat(0, height(V), 1);
    V.metric_margin = V.joint_margin;
    V.pass_DG = isfinite(V.DG_rob) & (V.DG_rob >= reqDG);
    V.pass_DA = isfinite(V.DA_rob) & (V.DA_rob >= reqDA);
    V.pass_DT = isfinite(V.DT_rob) & (V.DT_rob >= reqDT);
    V.pass_PR = isfinite(V.pass_ratio) & (V.pass_ratio >= pass_ratio_threshold);
    V.metric_pass = V.pass_DG & V.pass_DA & V.pass_DT;
    V.feasible_flag = V.metric_pass & V.pass_PR;

    V.metric_value_clipped = max(V.metric_value, 0);
    V.metric_value_log10 = local_safe_log10(V.metric_value_clipped);
    V.is_transition_candidate = V.metric_pass | V.pass_PR | V.feasible_flag;
    V.is_pareto_candidate = V.feasible_flag;

    V = movevars(V, {'metric_name','metric_value','metric_threshold','metric_margin','pass_DG','pass_DA','pass_DT','pass_PR','metric_pass','feasible_flag','metric_value_clipped','metric_value_log10','is_transition_candidate','is_pareto_candidate'}, 'After', 'Ns');
end


function y = local_safe_log10(x)

    y = nan(size(x));
    mask = isfinite(x) & (x > 0);
    y(mask) = log10(x(mask));
end


function x = local_min_or_nan(v)

    if isempty(v)
        x = NaN;
    else
        x = min(v);
    end
end


function x = local_min_positive_or_nan(v)

    mask = isfinite(v) & (v > 0);
    if ~any(mask)
        x = NaN;
    else
        x = min(v(mask));
    end
end
