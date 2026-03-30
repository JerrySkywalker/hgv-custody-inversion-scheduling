function cubes = build_stage09_multilayer_heatmaps(views, cfg, mode_tag)
%BUILD_STAGE09_MULTILAYER_HEATMAPS
% Build standard cubes for future multilayer heatmap plotting.
%
% Outputs
%   cubes.metric_over_h_i_P
%   cubes.closure_over_h_i_P
%   cubes.index_tables
%   cubes.files.*

    if nargin < 3 || isempty(mode_tag)
        mode_tag = 'phase1';
    end

    if nargin < 2 || isempty(cfg)
        error('build_stage09_multilayer_heatmaps:MissingCfg', 'cfg is required.');
    end

    tables_dir = cfg.paths.tables;
    if ~exist(tables_dir, 'dir')
        mkdir(tables_dir);
    end
    run_tag = char(string(cfg.stage09.run_tag));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    % use DG view as reference grid
    Vref = views.DG.table;
    h_vals = unique(Vref.h_km(:)).';
    i_vals = unique(Vref.i_deg(:)).';
    P_vals = unique(Vref.P(:)).';

    metric_names = {'DG','DA','DT'};
    nM = numel(metric_names);
    nH = numel(h_vals);
    nI = numel(i_vals);
    nP = numel(P_vals);

    cube_metric = nan(nM, nH, nI, nP);
    cube_metric_log10 = nan(nM, nH, nI, nP);
    cube_metric_minNs = nan(nM, nH, nI, nP);

    for m = 1:nM
        V = views.(metric_names{m}).table;
        for hh = 1:nH
            for ii = 1:nI
                for pp = 1:nP
                    Tsel = V(V.h_km == h_vals(hh) & V.i_deg == i_vals(ii) & V.P == P_vals(pp) & V.feasible_flag, :);
                    if isempty(Tsel)
                        continue;
                    end
                    [~, idxBest] = max(Tsel.metric_value);
                    rowBest = Tsel(idxBest, :);
                    cube_metric(m, hh, ii, pp) = rowBest.metric_value;
                    cube_metric_log10(m, hh, ii, pp) = rowBest.metric_value_log10;
                    cube_metric_minNs(m, hh, ii, pp) = min(Tsel.Ns);
                end
            end
        end
    end

    % closure cube layers:
    % 1 = joint_feasible (0/1 mean over T,F)
    % 2 = DG best feasible metric value
    % 3 = DA best feasible metric value
    % 4 = DT best feasible metric value
    cube_closure = nan(4, nH, nI, nP);
    Vjoint = views.joint.table;
    for hh = 1:nH
        for ii = 1:nI
            for pp = 1:nP
                Tj = Vjoint(Vjoint.h_km == h_vals(hh) & Vjoint.i_deg == i_vals(ii) & Vjoint.P == P_vals(pp), :);
                if isempty(Tj)
                    continue;
                end
                cube_closure(1, hh, ii, pp) = mean(double(Tj.feasible_flag));
                cube_closure(2, hh, ii, pp) = local_best_metric(views.DG.table, h_vals(hh), i_vals(ii), P_vals(pp));
                cube_closure(3, hh, ii, pp) = local_best_metric(views.DA.table, h_vals(hh), i_vals(ii), P_vals(pp));
                cube_closure(4, hh, ii, pp) = local_best_metric(views.DT.table, h_vals(hh), i_vals(ii), P_vals(pp));
            end
        end
    end

    index_h = table((1:nH).', h_vals(:), 'VariableNames', {'h_idx','h_km'});
    index_i = table((1:nI).', i_vals(:), 'VariableNames', {'i_idx','i_deg'});
    index_P = table((1:nP).', P_vals(:), 'VariableNames', {'P_idx','P'});
    index_metric = table((1:nM).', string(metric_names(:)), 'VariableNames', {'metric_idx','metric_name'});
    index_closure = table((1:4).', ["joint_feasible_ratio";"DG_best";"DA_best";"DT_best"], ...
        'VariableNames', {'layer_idx','layer_name'});

    mat_file = fullfile(tables_dir, sprintf('stage09_multilayer_heatmaps_%s_%s_%s.mat', run_tag, mode_tag, timestamp));
    save(mat_file, 'cube_metric', 'cube_metric_log10', 'cube_metric_minNs', 'cube_closure', ...
        'h_vals', 'i_vals', 'P_vals', 'metric_names');

    h_csv = fullfile(tables_dir, sprintf('stage09_multilayer_h_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    i_csv = fullfile(tables_dir, sprintf('stage09_multilayer_i_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    p_csv = fullfile(tables_dir, sprintf('stage09_multilayer_P_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    m_csv = fullfile(tables_dir, sprintf('stage09_multilayer_metric_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    c_csv = fullfile(tables_dir, sprintf('stage09_multilayer_closure_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));

    writetable(index_h, h_csv);
    writetable(index_i, i_csv);
    writetable(index_P, p_csv);
    writetable(index_metric, m_csv);
    writetable(index_closure, c_csv);

    fprintf('\n');
    fprintf('========= Stage09 Multilayer Heatmap Cubes =========\n');
    fprintf('run_tag      : %s\n', run_tag);
    fprintf('mode_tag     : %s\n', mode_tag);
    fprintf('cube_metric  : [%d x %d x %d x %d]\n', size(cube_metric,1), size(cube_metric,2), size(cube_metric,3), size(cube_metric,4));
    fprintf('cube_closure : [%d x %d x %d x %d]\n', size(cube_closure,1), size(cube_closure,2), size(cube_closure,3), size(cube_closure,4));
    fprintf('mat file     : %s\n', mat_file);
    fprintf('====================================================\n\n');

    cubes = struct();
    cubes.metric_over_h_i_P = cube_metric;
    cubes.metric_log10_over_h_i_P = cube_metric_log10;
    cubes.metric_minNs_over_h_i_P = cube_metric_minNs;
    cubes.closure_over_h_i_P = cube_closure;
    cubes.index_tables = struct('h', index_h, 'i', index_i, 'P', index_P, 'metric', index_metric, 'closure', index_closure);
    cubes.files = struct('mat_file', mat_file, 'h_csv', h_csv, 'i_csv', i_csv, 'p_csv', p_csv, 'metric_csv', m_csv, 'closure_csv', c_csv);
end


function v = local_best_metric(V, h0, i0, P0)

    Tsel = V(V.h_km == h0 & V.i_deg == i0 & V.P == P0 & V.feasible_flag, :);
    if isempty(Tsel)
        v = NaN;
    else
        v = max(Tsel.metric_value);
    end
end
