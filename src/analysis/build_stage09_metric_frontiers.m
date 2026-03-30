function frontiers = build_stage09_metric_frontiers(views, cfg, mode_tag)
%BUILD_STAGE09_METRIC_FRONTIERS
% Build frontier / heatmap / pareto / transition tables for DG / DA / DT / joint.

    if nargin < 3 || isempty(mode_tag)
        mode_tag = 'phase1';
    end

    if nargin < 2 || isempty(cfg)
        error('build_stage09_metric_frontiers:MissingCfg', 'cfg is required.');
    end

    metrics = {'DG','DA','DT','joint'};
    tables_dir = cfg.paths.tables;
    if ~exist(tables_dir, 'dir')
        mkdir(tables_dir);
    end
    run_tag = char(string(cfg.stage09.run_tag));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    frontiers = struct();

    for k = 1:numel(metrics)
        name = metrics{k};
        V = views.(name).table;

        F_i = local_frontier_by_i(V);
        F_iP_minNs = local_minNs_by_iP(V);
        F_iP_best = local_bestMetric_by_iP(V);
        F_pareto = local_pareto_frontier(V);
        F_pr = local_transition_passratio(V);
        F_metric = local_transition_metric(V);
        F_summary = local_transition_summary(V, F_i);

        prefix = sprintf('stage09_%s_', lower(name));
        csv_frontier = fullfile(tables_dir, sprintf('%sfrontier_by_i_%s_%s_%s.csv', prefix, run_tag, mode_tag, timestamp));
        csv_minNs = fullfile(tables_dir, sprintf('%sminNs_by_iP_%s_%s_%s.csv', prefix, run_tag, mode_tag, timestamp));
        csv_best = fullfile(tables_dir, sprintf('%sbestMetric_by_iP_%s_%s_%s.csv', prefix, run_tag, mode_tag, timestamp));
        csv_pareto = fullfile(tables_dir, sprintf('%spareto_frontier_%s_%s_%s.csv', prefix, run_tag, mode_tag, timestamp));
        csv_pr = fullfile(tables_dir, sprintf('%stransition_passratio_%s_%s_%s.csv', prefix, run_tag, mode_tag, timestamp));
        csv_metric = fullfile(tables_dir, sprintf('%stransition_metric_%s_%s_%s.csv', prefix, run_tag, mode_tag, timestamp));
        csv_summary = fullfile(tables_dir, sprintf('%stransition_summary_%s_%s_%s.csv', prefix, run_tag, mode_tag, timestamp));

        writetable(F_i, csv_frontier);
        writetable(F_iP_minNs, csv_minNs);
        writetable(F_iP_best, csv_best);
        writetable(F_pareto, csv_pareto);
        writetable(F_pr, csv_pr);
        writetable(F_metric, csv_metric);
        writetable(F_summary, csv_summary);

        frontiers.(name) = struct( ...
            'frontier_by_i', F_i, ...
            'minNs_by_iP', F_iP_minNs, ...
            'bestMetric_by_iP', F_iP_best, ...
            'pareto_frontier', F_pareto, ...
            'transition_passratio', F_pr, ...
            'transition_metric', F_metric, ...
            'transition_summary', F_summary, ...
            'files', struct( ...
                'frontier_by_i', csv_frontier, ...
                'minNs_by_iP', csv_minNs, ...
                'bestMetric_by_iP', csv_best, ...
                'pareto_frontier', csv_pareto, ...
                'transition_passratio', csv_pr, ...
                'transition_metric', csv_metric, ...
                'transition_summary', csv_summary));
    end

    fprintf('\n');
    fprintf('========== Stage09 Metric Frontiers (Phase1) ==========\n');
    fprintf('run_tag  : %s\n', run_tag);
    fprintf('mode_tag : %s\n', mode_tag);
    for k = 1:numel(metrics)
        name = metrics{k};
        fprintf('%-6s frontier rows : %d | pareto rows : %d | transition-summary rows : %d\n', ...
            name, ...
            height(frontiers.(name).frontier_by_i), ...
            height(frontiers.(name).pareto_frontier), ...
            height(frontiers.(name).transition_summary));
    end
    fprintf('=======================================================\n\n');
end


function Tfront = local_frontier_by_i(V)

    ivec = unique(V.i_deg(:));
    rows = cell(0,1);
    for ii = 1:numel(ivec)
        i0 = ivec(ii);
        Ti = V(V.i_deg == i0 & V.feasible_flag, :);
        if isempty(Ti)
            continue;
        end
        nsmin = min(Ti.Ns);
        Tm = Ti(Ti.Ns == nsmin, :);
        Tm = sortrows(Tm, {'metric_value','P','T','h_km'}, {'descend','ascend','ascend','ascend'});
        rows{end+1,1} = Tm(1, :); %#ok<AGROW>
    end

    if isempty(rows)
        Tfront = table();
        return;
    end

    Tfront = vertcat(rows{:});
    Tfront = Tfront(:, {'h_km','i_deg','P','T','F','Ns','metric_name','metric_value','metric_margin','pass_ratio','feasible_flag'});
    Tfront.Properties.VariableNames{'Ns'} = 'frontier_Ns';
    Tfront.Properties.VariableNames{'metric_value'} = 'frontier_metric';
    Tfront.Properties.VariableNames{'metric_margin'} = 'frontier_margin';
end


function Tout = local_minNs_by_iP(V)

    i_unique = unique(V.i_deg(:));
    P_unique = unique(V.P(:));
    rows = cell(0,1);

    for ii = 1:numel(i_unique)
        for pp = 1:numel(P_unique)
            Tsel = V(V.i_deg == i_unique(ii) & V.P == P_unique(pp) & V.feasible_flag, :);
            if isempty(Tsel)
                continue;
            end
            nsmin = min(Tsel.Ns);
            Tm = Tsel(Tsel.Ns == nsmin, :);
            Tm = sortrows(Tm, {'metric_value','T','h_km'}, {'descend','ascend','ascend'});
            rows{end+1,1} = Tm(1, :); %#ok<AGROW>
        end
    end

    if isempty(rows)
        Tout = table();
        return;
    end

    Tout = vertcat(rows{:});
    Tout = Tout(:, {'h_km','i_deg','P','T','F','Ns','metric_name','metric_value','pass_ratio','feasible_flag'});
    Tout.Properties.VariableNames{'Ns'} = 'min_feasible_Ns';
    Tout.Properties.VariableNames{'metric_value'} = 'metric_at_minNs';
end


function Tout = local_bestMetric_by_iP(V)

    i_unique = unique(V.i_deg(:));
    P_unique = unique(V.P(:));
    rows = cell(0,1);

    for ii = 1:numel(i_unique)
        for pp = 1:numel(P_unique)
            Tsel = V(V.i_deg == i_unique(ii) & V.P == P_unique(pp) & V.feasible_flag, :);
            if isempty(Tsel)
                continue;
            end
            vmax = max(Tsel.metric_value);
            Tm = Tsel(Tsel.metric_value == vmax, :);
            Tm = sortrows(Tm, {'Ns','T','h_km'}, {'ascend','ascend','ascend'});
            rows{end+1,1} = Tm(1, :); %#ok<AGROW>
        end
    end

    if isempty(rows)
        Tout = table();
        return;
    end

    Tout = vertcat(rows{:});
    Tout = Tout(:, {'h_km','i_deg','P','T','F','Ns','metric_name','metric_value','pass_ratio','feasible_flag'});
    Tout.Properties.VariableNames{'metric_value'} = 'best_metric';
    Tout.Properties.VariableNames{'Ns'} = 'Ns_at_best_metric';
end


function Tpareto = local_pareto_frontier(V)

    Tfeas = V(V.feasible_flag, :);
    if isempty(Tfeas)
        Tpareto = table();
        return;
    end

    Ns_unique = unique(Tfeas.Ns(:));
    rows = cell(0,1);
    current_best = -inf;

    for kk = 1:numel(Ns_unique)
        ns0 = Ns_unique(kk);
        Tn = Tfeas(Tfeas.Ns == ns0, :);
        vmax = max(Tn.metric_value);
        Tm = Tn(Tn.metric_value == vmax, :);
        Tm = sortrows(Tm, {'P','T','h_km'}, {'ascend','ascend','ascend'});
        row = Tm(1, :);
        if row.metric_value > current_best
            rows{end+1,1} = row; %#ok<AGROW>
            current_best = row.metric_value;
        end
    end

    Tpareto = vertcat(rows{:});
    Tpareto = Tpareto(:, {'h_km','i_deg','P','T','F','Ns','metric_name','metric_value','pass_ratio','feasible_flag'});
end


function Tpr = local_transition_passratio(V)

    i_unique = unique(V.i_deg(:));
    Ns_unique = unique(V.Ns(:));
    rows = cell(0,1);

    for ii = 1:numel(i_unique)
        for kk = 1:numel(Ns_unique)
            Tsel = V(V.i_deg == i_unique(ii) & V.Ns == Ns_unique(kk), :);
            if isempty(Tsel)
                continue;
            end
            prmax = max(Tsel.pass_ratio);
            Tm = Tsel(Tsel.pass_ratio == prmax, :);
            Tm = sortrows(Tm, {'metric_value','P','T','h_km'}, {'descend','ascend','ascend','ascend'});
            row = Tm(1, :);
            row.pass_ratio = prmax;
            rows{end+1,1} = row; %#ok<AGROW>
        end
    end

    Tpr = vertcat(rows{:});
    Tpr = Tpr(:, {'h_km','i_deg','P','T','F','Ns','metric_name','metric_value','pass_ratio'});
end


function Tmetric = local_transition_metric(V)

    i_unique = unique(V.i_deg(:));
    Ns_unique = unique(V.Ns(:));
    rows = cell(0,1);

    for ii = 1:numel(i_unique)
        for kk = 1:numel(Ns_unique)
            Tsel = V(V.i_deg == i_unique(ii) & V.Ns == Ns_unique(kk), :);
            if isempty(Tsel)
                continue;
            end
            vmax = max(Tsel.metric_value);
            Tm = Tsel(Tsel.metric_value == vmax, :);
            Tm = sortrows(Tm, {'pass_ratio','P','T','h_km'}, {'descend','ascend','ascend','ascend'});
            rows{end+1,1} = Tm(1, :); %#ok<AGROW>
        end
    end

    Tmetric = vertcat(rows{:});
    Tmetric = Tmetric(:, {'h_km','i_deg','P','T','F','Ns','metric_name','metric_value','pass_ratio'});
end


function Tsum = local_transition_summary(V, Tfront)

    i_unique = unique(V.i_deg(:));
    rows = cell(0,1);

    for ii = 1:numel(i_unique)
        i0 = i_unique(ii);
        Ti = V(V.i_deg == i0, :);

        first_pass_ratio = local_first_Ns(Ti.pass_PR, Ti.Ns);
        first_metric_pass = local_first_Ns(Ti.metric_pass, Ti.Ns);
        first_feasible = local_first_Ns(Ti.feasible_flag, Ti.Ns);

        Tf = Tfront(Tfront.i_deg == i0, :);
        if isempty(Tf)
            frontier_Ns = NaN; frontier_metric = NaN; frontier_h = NaN; frontier_P = NaN; frontier_T = NaN;
        else
            frontier_Ns = Tf.frontier_Ns(1);
            frontier_metric = Tf.frontier_metric(1);
            frontier_h = Tf.h_km(1);
            frontier_P = Tf.P(1);
            frontier_T = Tf.T(1);
        end

        rows{end+1,1} = table(i0, first_pass_ratio, first_metric_pass, first_feasible, ...
            frontier_h, frontier_P, frontier_T, frontier_Ns, frontier_metric, ...
            'VariableNames', {'i_deg','first_Ns_passratio1','first_Ns_metric_pass','first_Ns_feasible', ...
                              'frontier_h_km','frontier_P','frontier_T','frontier_Ns','frontier_metric'}); %#ok<AGROW>
    end

    Tsum = vertcat(rows{:});
end


function ns = local_first_Ns(mask, Ns)

    idx = find(mask);
    if isempty(idx)
        ns = NaN;
    else
        ns = min(Ns(idx));
    end
end
