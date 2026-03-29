function pack = build_stage05_stage09_comparison_tables(out05, out09, cfg05, cfg09, timestamp)
%BUILD_STAGE05_STAGE09_COMPARISON_TABLES
% Build and export Stage05-vs-Stage09 DG-only comparison tables.

    if nargin < 3 || isempty(cfg05)
        cfg05 = default_params();
    end
    if nargin < 4 || isempty(cfg09)
        cfg09 = default_params();
    end
    if nargin < 5 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    cfg09 = stage09_prepare_cfg(cfg09);
    cfg09.project_stage = 'stage09_stage05_dg_only_compare';
    cfg09 = configure_stage_output_paths(cfg09);

    ensure_dir(cfg09.paths.tables);

    stage05_table = local_normalize_stage05_table( ...
        local_extract_stage05_full_table(out05), cfg05);
    stage09_table = local_normalize_stage09_table( ...
        local_extract_stage09_full_table(out09), cfg09);

    main_compare_table = local_build_main_compare_table(stage05_table, stage09_table);
    frontier_compare_table = local_build_frontier_compare_table(stage05_table, stage09_table);
    heatmap_compare_table = local_build_heatmap_compare_table(stage05_table, stage09_table);
    passratio_profile_compare_table = local_build_passratio_profile_compare_table(stage05_table, stage09_table);

    run_tag = char(string(cfg09.stage09.run_tag));
    files = struct();
    files.main_compare_csv = fullfile(cfg09.paths.tables, ...
        sprintf('stage09_stage05_dg_only_main_compare_%s_%s.csv', run_tag, timestamp));
    files.frontier_compare_csv = fullfile(cfg09.paths.tables, ...
        sprintf('stage09_stage05_dg_only_frontier_compare_%s_%s.csv', run_tag, timestamp));
    files.heatmap_compare_csv = fullfile(cfg09.paths.tables, ...
        sprintf('stage09_stage05_dg_only_heatmap_compare_%s_%s.csv', run_tag, timestamp));

    writetable(main_compare_table, files.main_compare_csv);
    writetable(frontier_compare_table, files.frontier_compare_csv);
    writetable(heatmap_compare_table, files.heatmap_compare_csv);

    pack = struct();
    pack.timestamp = timestamp;
    pack.run_tag = string(run_tag);
    pack.stage05_table = stage05_table;
    pack.stage09_table = stage09_table;
    pack.stage05_feasible_table = stage05_table(stage05_table.feasible_flag, :);
    pack.stage09_feasible_table = stage09_table(stage09_table.feasible_flag, :);
    pack.main_compare_table = main_compare_table;
    pack.frontier_compare_table = frontier_compare_table;
    pack.heatmap_compare_table = heatmap_compare_table;
    pack.passratio_profile_compare_table = passratio_profile_compare_table;
    pack.gamma_req_stage05 = local_extract_stage05_gamma_req(out05, stage05_table);
    pack.gamma_req_stage09 = local_extract_stage09_gamma_req(out09, cfg09);
    pack.files = files;
end


function T = local_extract_stage05_full_table(out05)

    if isstruct(out05)
        if isfield(out05, 'grid') && istable(out05.grid)
            T = out05.grid;
            return;
        end
        if isfield(out05, 'out1') && isstruct(out05.out1) && ...
                isfield(out05.out1, 'grid') && istable(out05.out1.grid)
            T = out05.out1.grid;
            return;
        end
        if isfield(out05, 'out') && isstruct(out05.out) && ...
                isfield(out05.out, 'grid') && istable(out05.out.grid)
            T = out05.out.grid;
            return;
        end
    end

    error('Unable to extract Stage05 full table from out05.');
end


function T = local_extract_stage09_full_table(out09)

    if isstruct(out09)
        if isfield(out09, 'full_theta_table') && istable(out09.full_theta_table)
            T = out09.full_theta_table;
            return;
        end
        if isfield(out09, 's4') && isstruct(out09.s4) && ...
                isfield(out09.s4, 'full_theta_table') && istable(out09.s4.full_theta_table)
            T = out09.s4.full_theta_table;
            return;
        end
        if isfield(out09, 'out9_4') && isstruct(out09.out9_4) && ...
                isfield(out09.out9_4, 'full_theta_table') && istable(out09.out9_4.full_theta_table)
            T = out09.out9_4.full_theta_table;
            return;
        end
        if isfield(out09, 'out') && isstruct(out09.out) && ...
                isfield(out09.out, 'full_theta_table') && istable(out09.out.full_theta_table)
            T = out09.out.full_theta_table;
            return;
        end
    end

    error('Unable to extract Stage09 full theta table from out09.');
end


function T = local_normalize_stage05_table(T, cfg05)

    if ~istable(T)
        error('Stage05 comparison input must be a table.');
    end

    if ~ismember('h_km', T.Properties.VariableNames)
        T.h_km = repmat(cfg05.stage05.h_fixed_km, height(T), 1);
    end
    if ~ismember('F', T.Properties.VariableNames)
        T.F = repmat(cfg05.stage05.F_fixed, height(T), 1);
    end
    if ~ismember('Ns', T.Properties.VariableNames)
        T.Ns = T.P .* T.T;
    end
    if ~ismember('feasible_flag', T.Properties.VariableNames)
        if ismember('feasible', T.Properties.VariableNames)
            T.feasible_flag = logical(T.feasible);
        else
            error('Stage05 table is missing feasible_flag.');
        end
    end
    if ~ismember('rank_score', T.Properties.VariableNames)
        T.rank_score = nan(height(T), 1);
    end
    if ~ismember('D_G_min', T.Properties.VariableNames)
        error('Stage05 table is missing D_G_min.');
    end
    if ~ismember('pass_ratio', T.Properties.VariableNames)
        error('Stage05 table is missing pass_ratio.');
    end

    T.h_km = double(T.h_km);
    T.i_deg = double(T.i_deg);
    T.P = double(T.P);
    T.T = double(T.T);
    T.F = double(T.F);
    T.Ns = double(T.Ns);
    T.D_G_min = double(T.D_G_min);
    T.pass_ratio = double(T.pass_ratio);
    T.rank_score = double(T.rank_score);
    T.feasible_flag = logical(T.feasible_flag);
    T.key = string(local_make_design_key(T.h_km, T.i_deg, T.P, T.T, T.F));

    local_assert_unique_keys(T.key, 'Stage05');
    T = sortrows(T, {'h_km','i_deg','P','T','F'}, {'ascend','ascend','ascend','ascend','ascend'});
end


function T = local_normalize_stage09_table(T, cfg09)

    if ~istable(T)
        error('Stage09 comparison input must be a table.');
    end

    must_have = {'h_km','i_deg','P','T','F','Ns','DG_rob','pass_ratio'};
    for k = 1:numel(must_have)
        if ~ismember(must_have{k}, T.Properties.VariableNames)
            error('Stage09 full theta table is missing %s.', must_have{k});
        end
    end

    if ~ismember('joint_feasible', T.Properties.VariableNames)
        if ismember('feasible_flag', T.Properties.VariableNames)
            T.joint_feasible = logical(T.feasible_flag);
        else
            error('Stage09 table is missing joint_feasible.');
        end
    end
    if ~ismember('feasible_stage05_compat', T.Properties.VariableNames)
        T.feasible_stage05_compat = isfinite(T.DG_rob) & ...
            (T.DG_rob >= cfg09.stage09.require_DG_min) & ...
            isfinite(T.pass_ratio) & ...
            (T.pass_ratio >= cfg09.stage09.require_pass_ratio);
    end
    if ~ismember('joint_margin', T.Properties.VariableNames)
        T.joint_margin = nan(height(T), 1);
    end

    T.h_km = double(T.h_km);
    T.i_deg = double(T.i_deg);
    T.P = double(T.P);
    T.T = double(T.T);
    T.F = double(T.F);
    T.Ns = double(T.Ns);
    T.DG_rob = double(T.DG_rob);
    T.pass_ratio = double(T.pass_ratio);
    T.joint_margin = double(T.joint_margin);
    T.joint_feasible = logical(T.joint_feasible);
    T.feasible_stage05_compat = logical(T.feasible_stage05_compat);
    T.feasible_flag = T.feasible_stage05_compat;
    T.key = string(local_make_design_key(T.h_km, T.i_deg, T.P, T.T, T.F));

    local_assert_unique_keys(T.key, 'Stage09');
    T = sortrows(T, {'h_km','i_deg','P','T','F'}, {'ascend','ascend','ascend','ascend','ascend'});
end


function Tmain = local_build_main_compare_table(T05, T09)

    key_all = local_union_keys(T05.key, T09.key);
    rows = cell(numel(key_all), 1);

    for k = 1:numel(key_all)
        key_k = key_all(k);
        row05 = local_find_row_by_key(T05, key_k);
        row09 = local_find_row_by_key(T09, key_k);

        has05 = ~isempty(row05);
        has09 = ~isempty(row09);

        row = struct();
        row.h_km = local_pick_numeric(row05, row09, 'h_km');
        row.i_deg = local_pick_numeric(row05, row09, 'i_deg');
        row.P = local_pick_numeric(row05, row09, 'P');
        row.T = local_pick_numeric(row05, row09, 'T');
        row.F = local_pick_numeric(row05, row09, 'F');
        row.Ns = local_pick_numeric(row05, row09, 'Ns');
        row.key = key_k;
        row.present_stage05 = has05;
        row.present_stage09 = has09;
        row.row_match = has05 && has09;
        row.Ns_match = has05 && has09 && local_equal_numeric(row05.Ns, row09.Ns);
        row.DG_stage05 = local_pick_value(row05, 'D_G_min');
        row.DG_stage09 = local_pick_value(row09, 'DG_rob');
        row.DG_abs_diff = local_abs_diff(row.DG_stage05, row.DG_stage09);
        row.pass_stage05 = local_pick_value(row05, 'pass_ratio');
        row.pass_stage09 = local_pick_value(row09, 'pass_ratio');
        row.pass_abs_diff = local_abs_diff(row.pass_stage05, row.pass_stage09);
        row.feas_stage05 = local_pick_flag(row05, 'feasible_flag');
        row.feas_stage09 = local_pick_flag(row09, 'feasible_flag');
        row.feas_match = has05 && has09 && local_equal_flag(row.feas_stage05, row.feas_stage09);
        rows{k} = row;
    end

    Tmain = struct2table(vertcat(rows{:}));
    Tmain = sortrows(Tmain, {'h_km','i_deg','P','T','F'}, {'ascend','ascend','ascend','ascend','ascend'});
end


function Tfront = local_build_frontier_compare_table(T05, T09)

    i_all = unique([T05.i_deg(:); T09.i_deg(:)]).';
    rows = cell(numel(i_all), 1);

    for k = 1:numel(i_all)
        i_deg = i_all(k);
        sub05 = T05(T05.i_deg == i_deg & T05.feasible_flag, :);
        sub09 = T09(T09.i_deg == i_deg & T09.feasible_flag, :);

        best05 = local_pick_stage05_frontier_row(sub05);
        best09 = local_pick_stage09_frontier_row(sub09);

        has05 = ~isempty(best05);
        has09 = ~isempty(best09);
        Ns05 = local_pick_value(best05, 'Ns');
        Ns09 = local_pick_value(best09, 'Ns');
        ns_match = local_equal_or_both_nan(Ns05, Ns09);
        pt_match = local_equal_or_both_nan(local_pick_value(best05, 'P'), local_pick_value(best09, 'P')) && ...
            local_equal_or_both_nan(local_pick_value(best05, 'T'), local_pick_value(best09, 'T'));

        row = struct();
        row.i_deg = i_deg;
        row.Ns_min_stage05 = Ns05;
        row.Ns_min_stage09 = Ns09;
        row.P_stage05 = local_pick_value(best05, 'P');
        row.T_stage05 = local_pick_value(best05, 'T');
        row.P_stage09 = local_pick_value(best09, 'P');
        row.T_stage09 = local_pick_value(best09, 'T');
        row.stage05_PT_set = local_pt_set_string(sub05);
        row.stage09_PT_set = local_pt_set_string(sub09);
        row.frontier_match_flag = ns_match;
        row.frontier_PT_match_flag = pt_match;
        row.frontier_equivalent_alt_flag = ns_match && has05 && has09 && ~pt_match;
        row.present_stage05 = has05;
        row.present_stage09 = has09;
        rows{k} = row;
    end

    Tfront = struct2table(vertcat(rows{:}));
    Tfront = sortrows(Tfront, 'i_deg', 'ascend');
end


function Theat = local_build_heatmap_compare_table(T05, T09)

    ip05 = unique(T05(:, {'i_deg','P'}), 'rows');
    ip09 = unique(T09(:, {'i_deg','P'}), 'rows');
    ip_all = unique([ip05; ip09], 'rows');

    rows = cell(height(ip_all), 1);
    for k = 1:height(ip_all)
        i_deg = ip_all.i_deg(k);
        P = ip_all.P(k);

        sub05 = T05(T05.i_deg == i_deg & T05.P == P & T05.feasible_flag, :);
        sub09 = T09(T09.i_deg == i_deg & T09.P == P & T09.feasible_flag, :);

        min05 = local_min_or_nan(sub05, 'Ns');
        min09 = local_min_or_nan(sub09, 'Ns');

        row = struct();
        row.i_deg = i_deg;
        row.P = P;
        row.minNs_stage05 = min05;
        row.minNs_stage09 = min09;
        row.minNs_diff = local_signed_diff(min09, min05);
        row.T_set_stage05 = local_t_set_string(sub05, min05);
        row.T_set_stage09 = local_t_set_string(sub09, min09);
        row.heatmap_match_flag = local_equal_or_both_nan(min05, min09);
        rows{k} = row;
    end

    Theat = struct2table(vertcat(rows{:}));
    Theat = sortrows(Theat, {'P','i_deg'}, {'ascend','ascend'});
end


function Tprof = local_build_passratio_profile_compare_table(T05, T09)

    in05 = unique(T05(:, {'i_deg','Ns'}), 'rows');
    in09 = unique(T09(:, {'i_deg','Ns'}), 'rows');
    in_all = unique([in05; in09], 'rows');

    rows = cell(height(in_all), 1);
    for k = 1:height(in_all)
        i_deg = in_all.i_deg(k);
        Ns = in_all.Ns(k);

        sub05 = T05(T05.i_deg == i_deg & T05.Ns == Ns, :);
        sub09 = T09(T09.i_deg == i_deg & T09.Ns == Ns, :);

        row = struct();
        row.i_deg = i_deg;
        row.Ns = Ns;
        row.pass_stage05 = local_max_or_nan(sub05, 'pass_ratio');
        row.pass_stage09 = local_max_or_nan(sub09, 'pass_ratio');
        row.pass_abs_diff = local_abs_diff(row.pass_stage05, row.pass_stage09);
        row.has_feasible_stage05 = any(sub05.feasible_flag);
        row.has_feasible_stage09 = any(sub09.feasible_flag);
        rows{k} = row;
    end

    Tprof = struct2table(vertcat(rows{:}));
    Tprof = sortrows(Tprof, {'i_deg','Ns'}, {'ascend','ascend'});
end


function row = local_find_row_by_key(T, key_k)

    idx = find(string(T.key) == string(key_k), 1, 'first');
    if isempty(idx)
        row = T([]);
    else
        row = T(idx, :);
    end
end


function key = local_make_design_key(h_km, i_deg, P, T, F)

    key = compose('h=%0.12g|i=%0.12g|P=%0.12g|T=%0.12g|F=%0.12g', ...
        h_km, i_deg, P, T, F);
end


function local_assert_unique_keys(key, label)

    key = string(key);
    [~, ~, ic] = unique(key);
    counts = accumarray(ic, 1);
    if any(counts > 1)
        error('%s comparison table contains duplicate design keys.', label);
    end
end


function keys = local_union_keys(key05, key09)

    key05 = string(key05);
    key09 = string(key09);
    keys = key05;
    extra = key09(~ismember(key09, key05));
    keys = [keys; extra];
end


function value = local_pick_numeric(row05, row09, field_name)

    if ~isempty(row05) && ismember(field_name, row05.Properties.VariableNames)
        value = row05.(field_name)(1);
    elseif ~isempty(row09) && ismember(field_name, row09.Properties.VariableNames)
        value = row09.(field_name)(1);
    else
        value = NaN;
    end
end


function value = local_pick_value(row, field_name)

    if isempty(row) || ~ismember(field_name, row.Properties.VariableNames)
        value = NaN;
    else
        value = row.(field_name)(1);
    end
end


function value = local_pick_flag(row, field_name)

    if isempty(row) || ~ismember(field_name, row.Properties.VariableNames)
        value = NaN;
    else
        value = double(logical(row.(field_name)(1)));
    end
end


function tf = local_equal_flag(a, b)

    tf = isfinite(a) && isfinite(b) && (round(a) == round(b));
end


function tf = local_equal_numeric(a, b)

    tf = isfinite(a) && isfinite(b) && abs(a - b) <= 1e-12;
end


function tf = local_equal_or_both_nan(a, b)

    if isnan(a) && isnan(b)
        tf = true;
    else
        tf = local_equal_numeric(a, b);
    end
end


function d = local_abs_diff(a, b)

    if isfinite(a) && isfinite(b)
        d = abs(a - b);
    else
        d = NaN;
    end
end


function d = local_signed_diff(a, b)

    if isfinite(a) && isfinite(b)
        d = a - b;
    else
        d = NaN;
    end
end


function best = local_pick_stage05_frontier_row(sub)

    if isempty(sub)
        best = sub([]);
        return;
    end

    sub = sortrows(sub, ...
        {'Ns','rank_score','D_G_min','pass_ratio','P','T'}, ...
        {'ascend','ascend','descend','descend','ascend','ascend'});
    best = sub(1, :);
end


function best = local_pick_stage09_frontier_row(sub)

    if isempty(sub)
        best = sub([]);
        return;
    end

    sub = sortrows(sub, ...
        {'Ns','joint_margin','DG_rob','pass_ratio','P','T'}, ...
        {'ascend','descend','descend','descend','ascend','ascend'});
    best = sub(1, :);
end


function txt = local_pt_set_string(sub)

    if isempty(sub)
        txt = "";
        return;
    end

    minNs = min(sub.Ns);
    sub = sub(sub.Ns == minNs, :);
    PT = unique(sub(:, {'P','T'}), 'rows');
    parts = strings(height(PT), 1);
    for k = 1:height(PT)
        parts(k) = sprintf('(%g,%g)', PT.P(k), PT.T(k));
    end
    txt = strjoin(parts, ',');
end


function txt = local_t_set_string(sub, minNs)

    if isempty(sub) || ~isfinite(minNs)
        txt = "";
        return;
    end

    sub = sub(sub.Ns == minNs, :);
    Tvals = unique(sub.T(:)).';
    txt = strjoin(compose('%g', Tvals), ',');
end


function val = local_min_or_nan(T, field_name)

    if isempty(T)
        val = NaN;
    else
        data = T.(field_name);
        data = data(isfinite(data));
        if isempty(data)
            val = NaN;
        else
            val = min(data);
        end
    end
end


function val = local_max_or_nan(T, field_name)

    if isempty(T)
        val = NaN;
    else
        data = T.(field_name);
        data = data(isfinite(data));
        if isempty(data)
            val = NaN;
        else
            val = max(data);
        end
    end
end


function gamma_req = local_extract_stage05_gamma_req(out05, stage05_table)

    gamma_req = NaN;

    try
        if isstruct(out05) && isfield(out05, 'summary') && isfield(out05.summary, 'gamma_req')
            gamma_req = out05.summary.gamma_req;
            return;
        end
        if isstruct(out05) && isfield(out05, 'out1') && isstruct(out05.out1) && ...
                isfield(out05.out1, 'summary') && isfield(out05.out1.summary, 'gamma_req')
            gamma_req = out05.out1.summary.gamma_req;
            return;
        end
    catch
    end

    if ismember('gamma_req', stage05_table.Properties.VariableNames)
        vals = stage05_table.gamma_req(isfinite(stage05_table.gamma_req));
        if ~isempty(vals)
            gamma_req = vals(1);
        end
    end
end


function gamma_req = local_extract_stage09_gamma_req(out09, cfg09)

    gamma_req = NaN;

    try
        if isstruct(out09) && isfield(out09, 's4') && isstruct(out09.s4) && ...
                isfield(out09.s4, 'gamma_info') && isfield(out09.s4.gamma_info, 'gamma_req')
            gamma_req = out09.s4.gamma_info.gamma_req;
            return;
        end
        if isstruct(out09) && isfield(out09, 'gamma_info') && isfield(out09.gamma_info, 'gamma_req')
            gamma_req = out09.gamma_info.gamma_req;
            return;
        end
        if isstruct(out09) && isfield(out09, 's1') && isstruct(out09.s1) && ...
                isfield(out09.s1, 'stage04_gamma_info') && isfield(out09.s1.stage04_gamma_info, 'gamma_req')
            gamma_req = out09.s1.stage04_gamma_info.gamma_req;
            return;
        end
    catch
    end

    if isfield(cfg09.stage09, 'gamma_req') && ~isempty(cfg09.stage09.gamma_req)
        gamma_req = cfg09.stage09.gamma_req;
    end
end
