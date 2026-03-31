function out = stage05_analyze_pareto_transition()
    % STAGE05_ANALYZE_PARETO_TRANSITION
    % Stage05.4:
    %   1) Global Pareto frontier in (Ns, D_G_min) over feasible configurations
    %   2) Inclination-wise threshold / transition diagnostics
    %   3) Save tables + figures for thesis use
    %
    % This version is designed to work robustly with the stable Stage05.2b output.
    %
    % Outputs:
    %   out.data_table
    %   out.feasible_table
    %   out.pareto_table
    %   out.transition_table
    %   out.files
    %
    % Author: ChatGPT (adapted for Stage05.2b-compatible workflow)
    
        local_project_startup();
    
        log_fid = [];
        try
            [project_root, results_dir, logs_dir] = local_project_root();
            figs_dir   = fullfile(results_dir, 'figs');
            tables_dir = fullfile(results_dir, 'tables');
            cache_dir  = fullfile(results_dir, 'cache');
    
            local_mkdir_if_needed(logs_dir);
            local_mkdir_if_needed(figs_dir);
            local_mkdir_if_needed(tables_dir);
            local_mkdir_if_needed(cache_dir);
    
            stamp = datestr(now, 'yyyymmdd_HHMMSS');
            log_path = fullfile(logs_dir, ['stage05_analyze_pareto_transition_' stamp '.log']);
            log_fid = fopen(log_path, 'w');
    
            local_log(log_fid, 'INFO', 'Stage05.4 started.');
    
            % -----------------------------------------------------------------
            % 1) Load Stage05 data
            % -----------------------------------------------------------------
            [T, source_info] = local_load_stage05_table(results_dir, cache_dir, log_fid);
            local_log(log_fid, 'INFO', 'Loaded Stage05 source: %s', source_info);
    
            % Normalize / standardize columns
            T = local_standardize_stage05_table(T);
    
            % Basic checks
            req = {'i_deg','P','T','Ns','D_G_min','pass_ratio','feasible'};
            for k = 1:numel(req)
                if ~ismember(req{k}, T.Properties.VariableNames)
                    error('Stage05.4:MissingColumn', 'Required column missing after standardization: %s', req{k});
                end
            end
    
            % Sort for readability
            T = sortrows(T, {'i_deg','P','T','Ns'});
    
            n_all = height(T);
            T_feas = T(T.feasible > 0, :);
    
            local_log(log_fid, 'INFO', 'Total rows      : %d', n_all);
            local_log(log_fid, 'INFO', 'Feasible rows   : %d', height(T_feas));
            local_log(log_fid, 'INFO', 'Inclination set : %s', mat2str(unique(T.i_deg(:)')));
    
            % -----------------------------------------------------------------
            % 2) Global Pareto frontier on feasible set
            %    Objective: minimize Ns, maximize D_G_min
            % -----------------------------------------------------------------
            pareto_mask = local_pareto_frontier(T_feas.Ns, T_feas.D_G_min);
            T_pareto = T_feas(pareto_mask, :);
            T_pareto = sortrows(T_pareto, {'Ns','D_G_min','i_deg','P','T'}, {'ascend','descend','ascend','ascend','ascend'});
    
            pareto_csv = fullfile(tables_dir, ['stage05_pareto_frontier_' stamp '.csv']);
            writetable(T_pareto, pareto_csv);
            local_log(log_fid, 'INFO', 'Pareto table saved: %s', pareto_csv);
    
            % -----------------------------------------------------------------
            % 3) Inclination-wise transition summary
            %    For each i and each Ns:
            %      - max pass_ratio envelope
            %      - max D_G_min envelope
            %      - min feasible D_G_min among feasible configs
            %      - first Ns reaching pass_ratio = 1
            % -----------------------------------------------------------------
            i_list  = unique(T.i_deg(:))';
            Ns_list = unique(T.Ns(:))';
    
            trans_rows = [];
            env_rows   = [];
    
            for ii = 1:numel(i_list)
                i0 = i_list(ii);
                Ti = T(T.i_deg == i0, :);
    
                first_Ns_pass1 = NaN;
                first_Ns_feas  = NaN;
    
                for jj = 1:numel(Ns_list)
                    ns0 = Ns_list(jj);
                    Tij = Ti(Ti.Ns == ns0, :);
                    if isempty(Tij)
                        continue;
                    end
    
                    max_pass = max(Tij.pass_ratio);
                    max_DG   = max(Tij.D_G_min);
    
                    feas_ij = Tij(Tij.feasible > 0, :);
                    if isempty(feas_ij)
                        min_feas_DG = NaN;
                        min_feas_P  = NaN;
                        min_feas_T  = NaN;
                    else
                        [~, idx_min_ns_feasDG] = min(feas_ij.D_G_min);
                        min_feas_DG = feas_ij.D_G_min(idx_min_ns_feasDG);
                        min_feas_P  = feas_ij.P(idx_min_ns_feasDG);
                        min_feas_T  = feas_ij.T(idx_min_ns_feasDG);
                    end
    
                    row_env = table(i0, ns0, max_pass, max_DG, min_feas_DG, min_feas_P, min_feas_T, ...
                        'VariableNames', {'i_deg','Ns','max_pass_ratio','max_D_G_min','min_feasible_D_G_min','min_feasible_P','min_feasible_T'});
                    env_rows = [env_rows; row_env]; %#ok<AGROW>
    
                    if isnan(first_Ns_pass1) && max_pass >= 1-1e-12
                        first_Ns_pass1 = ns0;
                    end
                    if isnan(first_Ns_feas) && ~isempty(feas_ij)
                        first_Ns_feas = ns0;
                    end
                end
    
                % Best feasible at this inclination: minimal Ns, tie-break by larger D_G_min
                Ti_feas = Ti(Ti.feasible > 0, :);
                if isempty(Ti_feas)
                    bestNs = NaN; bestDG = NaN; bestP = NaN; bestT = NaN;
                else
                    minNs_i = min(Ti_feas.Ns);
                    cand = Ti_feas(Ti_feas.Ns == minNs_i, :);
                    [~, idx_best_i] = max(cand.D_G_min);
                    bestNs = cand.Ns(idx_best_i);
                    bestDG = cand.D_G_min(idx_best_i);
                    bestP  = cand.P(idx_best_i);
                    bestT  = cand.T(idx_best_i);
                end
    
                row_trans = table(i0, first_Ns_pass1, first_Ns_feas, bestNs, bestDG, bestP, bestT, ...
                    'VariableNames', {'i_deg','first_Ns_pass1','first_Ns_feasible','frontier_Ns','frontier_D_G_min','frontier_P','frontier_T'});
                trans_rows = [trans_rows; row_trans]; %#ok<AGROW>
            end
    
            T_env = env_rows;
            T_trans = trans_rows;
    
            env_csv = fullfile(tables_dir, ['stage05_transition_envelope_' stamp '.csv']);
            trans_csv = fullfile(tables_dir, ['stage05_transition_summary_' stamp '.csv']);
            writetable(T_env, env_csv);
            writetable(T_trans, trans_csv);
            local_log(log_fid, 'INFO', 'Transition envelope table saved: %s', env_csv);
            local_log(log_fid, 'INFO', 'Transition summary  table saved: %s', trans_csv);
    
            % -----------------------------------------------------------------
            % 4) Figures
            % -----------------------------------------------------------------
            fig1 = local_plot_global_pareto(T_feas, T_pareto);
            fig1_path_png = fullfile(figs_dir, ['stage05_pareto_frontier_' stamp '.png']);
            fig1_path_fig = fullfile(figs_dir, ['stage05_pareto_frontier_' stamp '.fig']);
            saveas(fig1, fig1_path_png);
            savefig(fig1, fig1_path_fig);
            local_log(log_fid, 'INFO', 'Saved figure: %s', fig1_path_png);
    
            fig2 = local_plot_transition_passratio(T_env, i_list);
            fig2_path_png = fullfile(figs_dir, ['stage05_transition_passratio_' stamp '.png']);
            fig2_path_fig = fullfile(figs_dir, ['stage05_transition_passratio_' stamp '.fig']);
            saveas(fig2, fig2_path_png);
            savefig(fig2, fig2_path_fig);
            local_log(log_fid, 'INFO', 'Saved figure: %s', fig2_path_png);
    
            fig3 = local_plot_transition_DG(T_env, i_list);
            fig3_path_png = fullfile(figs_dir, ['stage05_transition_DG_' stamp '.png']);
            fig3_path_fig = fullfile(figs_dir, ['stage05_transition_DG_' stamp '.fig']);
            saveas(fig3, fig3_path_png);
            savefig(fig3, fig3_path_fig);
            local_log(log_fid, 'INFO', 'Saved figure: %s', fig3_path_png);
    
            fig4 = local_plot_transition_summary(T_trans);
            fig4_path_png = fullfile(figs_dir, ['stage05_transition_summary_' stamp '.png']);
            fig4_path_fig = fullfile(figs_dir, ['stage05_transition_summary_' stamp '.fig']);
            saveas(fig4, fig4_path_png);
            savefig(fig4, fig4_path_fig);
            local_log(log_fid, 'INFO', 'Saved figure: %s', fig4_path_png);
    
            close(fig1); close(fig2); close(fig3); close(fig4);
    
            % -----------------------------------------------------------------
            % 5) Console / output
            % -----------------------------------------------------------------
            local_log(log_fid, 'INFO', 'Stage05.4 finished.');
    
            fprintf('\n========== Stage05.4 Summary ==========\n');
            fprintf('Log file       : %s\n', log_path);
            fprintf('Pareto table   : %s\n', pareto_csv);
            fprintf('Envelope table : %s\n', env_csv);
            fprintf('Summary table  : %s\n', trans_csv);
            fprintf('Figure 1       : %s\n', fig1_path_png);
            fprintf('Figure 2       : %s\n', fig2_path_png);
            fprintf('Figure 3       : %s\n', fig3_path_png);
            fprintf('Figure 4       : %s\n', fig4_path_png);
            fprintf('Feasible count : %d\n', height(T_feas));
            fprintf('Pareto count   : %d\n', height(T_pareto));
            fprintf('=======================================\n');
    
            out = struct();
            out.data_table       = T;
            out.feasible_table   = T_feas;
            out.pareto_table     = T_pareto;
            out.transition_env   = T_env;
            out.transition_table = T_trans;
            out.files = struct( ...
                'log', log_path, ...
                'pareto_csv', pareto_csv, ...
                'env_csv', env_csv, ...
                'trans_csv', trans_csv, ...
                'fig1_png', fig1_path_png, ...
                'fig2_png', fig2_path_png, ...
                'fig3_png', fig3_path_png, ...
                'fig4_png', fig4_path_png);
    
            if log_fid > 0
                fclose(log_fid);
            end
    
        catch ME
            if log_fid > 0
                local_log(log_fid, 'ERROR', '%s', ME.message);
                fclose(log_fid);
            end
            rethrow(ME);
        end
    end
    
    % =========================================================================
    % Local helpers
    % =========================================================================
    
    function local_project_startup()
        % Try several common startup entry points
        tried = {};
        if exist('startup_project', 'file') == 2
            startup_project();
            return;
        end
        tried{end+1} = 'startup_project'; %#ok<AGROW>
    
        if exist('startup', 'file') == 2
            startup();
            return;
        end
        tried{end+1} = 'startup'; %#ok<AGROW>
    
        if exist('init_project_paths', 'file') == 2
            init_project_paths();
            return;
        end
        tried{end+1} = 'init_project_paths'; %#ok<AGROW>
    
        warning('Stage05.4:StartupNotFound', ...
            'No recognized startup function found. Tried: %s', strjoin(tried, ', '));
    end
    
    function [project_root, results_dir, logs_dir] = local_project_root()
        this_file = mfilename('fullpath');
        stage_dir = fileparts(this_file);
        project_root = fileparts(stage_dir);
        results_dir = fullfile(project_root, 'outputs', 'stage', 'stage05');
        logs_dir = fullfile(project_root, 'outputs', 'logs', 'stage05');
    end
    
    function local_mkdir_if_needed(d)
        if ~exist(d, 'dir')
            mkdir(d);
        end
    end
    
    function local_log(fid, level, fmt, varargin)
        msg = sprintf(fmt, varargin{:});
        tstr = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        line = sprintf('[%s][%s] %s', tstr, level, msg);
        fprintf('%s\n', line);
        if fid > 0
            fprintf(fid, '%s\n', line);
        end
    end
    
    function [T, source_info] = local_load_stage05_table(results_dir, cache_dir, log_fid)
        tables_dir = fullfile(results_dir, 'tables');
    
        % Priority 1: latest CSV from Stage05.2b
        csv_file = local_latest_file(tables_dir, 'stage05_nominal_search_results_*.csv');
        if ~isempty(csv_file)
            T = readtable(csv_file);
            source_info = csv_file;
            return;
        end
    
        % Priority 2: latest MAT cache
        mat_file = local_latest_file(cache_dir, 'stage05_nominal_walker_search_*.mat');
        if isempty(mat_file)
            error('Stage05.4:NoStage05Data', 'No Stage05 CSV or cache MAT found.');
        end
    
        S = load(mat_file);
        source_info = mat_file;
    
        % Try common top-level variable names
        cand_names = fieldnames(S);
        obj = [];
        for k = 1:numel(cand_names)
            v = S.(cand_names{k});
            if isstruct(v) && isfield(v, 'grid')
                obj = v;
                break;
            end
        end
    
        if isempty(obj)
            error('Stage05.4:BadCache', 'Could not find a struct containing field "grid" in cache MAT.');
        end
    
        grid_data = obj.grid;
        if istable(grid_data)
            T = grid_data;
            local_log(log_fid, 'INFO', 'Stage05 data loaded from cache table grid.');
        elseif isstruct(grid_data)
            T = struct2table(grid_data);
            local_log(log_fid, 'INFO', 'Stage05 data loaded from cache struct grid.');
        else
            error('Stage05.4:BadGridType', 'Unsupported grid type in cache.');
        end
    end
    
    function file_path = local_latest_file(folder, pattern)
        file_path = '';
        if ~exist(folder, 'dir')
            return;
        end
        D = dir(fullfile(folder, pattern));
        if isempty(D)
            return;
        end
        [~, idx] = max([D.datenum]);
        file_path = fullfile(folder, D(idx).name);
    end
    
    function T = local_standardize_stage05_table(T)
        % Convert variable names to a stable set:
        % i_deg, P, T, Ns, D_G_min, pass_ratio, feasible
    
        v = T.Properties.VariableNames;
    
        % i_deg
        name = local_pick_name(v, {'i_deg','inc_deg','inclination_deg','inclination','i'});
        if ~isempty(name) && ~strcmp(name, 'i_deg')
            T.Properties.VariableNames{strcmp(T.Properties.VariableNames, name)} = 'i_deg';
        end
    
        % P
        name = local_pick_name(v, {'P','p'});
        if ~isempty(name) && ~strcmp(name, 'P')
            T.Properties.VariableNames{strcmp(T.Properties.VariableNames, name)} = 'P';
        end
    
        % T
        v = T.Properties.VariableNames;
        name = local_pick_name(v, {'T','t'});
        if ~isempty(name) && ~strcmp(name, 'T')
            T.Properties.VariableNames{strcmp(T.Properties.VariableNames, name)} = 'T';
        end
    
        % Ns
        v = T.Properties.VariableNames;
        name = local_pick_name(v, {'Ns','N_s','Nsat','nSat','num_sat'});
        if ~isempty(name) && ~strcmp(name, 'Ns')
            T.Properties.VariableNames{strcmp(T.Properties.VariableNames, name)} = 'Ns';
        end
    
        % D_G_min
        v = T.Properties.VariableNames;
        name = local_pick_name(v, {'D_G_min','DG_min','dg_min','DgMin'});
        if ~isempty(name) && ~strcmp(name, 'D_G_min')
            T.Properties.VariableNames{strcmp(T.Properties.VariableNames, name)} = 'D_G_min';
        end
    
        % pass_ratio
        v = T.Properties.VariableNames;
        name = local_pick_name(v, {'pass_ratio','passRate','pass_ratio_max'});
        if ~isempty(name) && ~strcmp(name, 'pass_ratio')
            T.Properties.VariableNames{strcmp(T.Properties.VariableNames, name)} = 'pass_ratio';
        end
    
        % feasible
        v = T.Properties.VariableNames;
        name = local_pick_name(v, {'feasible','is_feasible','flag_feasible'});
        if ~isempty(name) && ~strcmp(name, 'feasible')
            T.Properties.VariableNames{strcmp(T.Properties.VariableNames, name)} = 'feasible';
        end
    
        % If feasible absent, infer
        if ~ismember('feasible', T.Properties.VariableNames)
            if ismember('pass_ratio', T.Properties.VariableNames) && ismember('D_G_min', T.Properties.VariableNames)
                T.feasible = double((T.pass_ratio >= 1-1e-12) & (T.D_G_min >= 1));
            else
                error('Stage05.4:CannotInferFeasible', 'Column "feasible" missing and cannot be inferred.');
            end
        end
    
        % Ensure numeric double columns
        num_vars = {'i_deg','P','T','Ns','D_G_min','pass_ratio','feasible'};
        for k = 1:numel(num_vars)
            if ismember(num_vars{k}, T.Properties.VariableNames)
                T.(num_vars{k}) = double(T.(num_vars{k}));
            end
        end
    end
    
    function name = local_pick_name(vnames, candidates)
        name = '';
        for i = 1:numel(candidates)
            idx = find(strcmp(vnames, candidates{i}), 1, 'first');
            if ~isempty(idx)
                name = vnames{idx};
                return;
            end
        end
    end
    
    function mask = local_pareto_frontier(x_cost, y_gain)
        % Pareto frontier for minimizing x_cost and maximizing y_gain
        n = numel(x_cost);
        mask = true(n,1);
        for i = 1:n
            for j = 1:n
                if j == i
                    continue;
                end
                dominates = (x_cost(j) <= x_cost(i)) && (y_gain(j) >= y_gain(i)) && ...
                            ((x_cost(j) < x_cost(i)) || (y_gain(j) > y_gain(i)));
                if dominates
                    mask(i) = false;
                    break;
                end
            end
        end
    end
    
    function fig = local_plot_global_pareto(T_feas, T_pareto)
        fig = figure('Color', 'w', 'Name', 'Stage05 Pareto Frontier', 'Position', [100 100 1100 700]);
    
        scatter(T_feas.Ns, T_feas.D_G_min, 70, T_feas.i_deg, 'filled', ...
            'MarkerFaceAlpha', 0.55, 'MarkerEdgeColor', [0.2 0.2 0.2]);
        hold on;
    
        [~, order] = sort(T_pareto.Ns, 'ascend');
        Tp = T_pareto(order, :);
    
        plot(Tp.Ns, Tp.D_G_min, '-k', 'LineWidth', 2.0);
        scatter(Tp.Ns, Tp.D_G_min, 120, 'r', 'o', 'LineWidth', 1.8);
    
        % Highlight minimal-Ns Pareto point
        [~, idx_best] = min(Tp.Ns);
        scatter(Tp.Ns(idx_best), Tp.D_G_min(idx_best), 280, 'p', ...
            'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.9 0], 'LineWidth', 1.5);
        text(Tp.Ns(idx_best)+1.5, Tp.D_G_min(idx_best), ...
            sprintf('best frontier: i=%g, P=%g, T=%g', Tp.i_deg(idx_best), Tp.P(idx_best), Tp.T(idx_best)), ...
            'FontSize', 12, 'Color', 'k');
    
        cb = colorbar;
        ylabel(cb, 'inclination i (deg)');
    
        xlabel('total satellites N_s');
        ylabel('D_G^{min}');
        title('Global Pareto frontier over feasible configurations');
        grid on;
        box on;
        set(gca, 'FontSize', 13);
    end
    
    function fig = local_plot_transition_passratio(T_env, i_list)
        fig = figure('Color', 'w', 'Name', 'Stage05 Transition PassRatio', 'Position', [120 120 1100 700]);
        hold on;
    
        cmap = lines(numel(i_list));
        for k = 1:numel(i_list)
            i0 = i_list(k);
            Ti = T_env(T_env.i_deg == i0, :);
            Ti = sortrows(Ti, 'Ns');
            plot(Ti.Ns, Ti.max_pass_ratio, '-o', ...
                'Color', cmap(k,:), 'LineWidth', 2.0, 'MarkerSize', 8, ...
                'DisplayName', sprintf('i=%g deg', i0));
        end
    
        xlabel('total satellites N_s');
        ylabel('max pass ratio under fixed i');
        title('Threshold diagnostic: pass-ratio envelope versus N_s');
        legend('Location', 'eastoutside');
        grid on;
        box on;
        ylim([0 1.05]);
        set(gca, 'FontSize', 13);
    end
    
    function fig = local_plot_transition_DG(T_env, i_list)
        fig = figure('Color', 'w', 'Name', 'Stage05 Transition DG', 'Position', [140 140 1100 700]);
        hold on;
    
        cmap = lines(numel(i_list));
        for k = 1:numel(i_list)
            i0 = i_list(k);
            Ti = T_env(T_env.i_deg == i0, :);
            Ti = sortrows(Ti, 'Ns');
            plot(Ti.Ns, Ti.max_D_G_min, '-s', ...
                'Color', cmap(k,:), 'LineWidth', 2.0, 'MarkerSize', 7, ...
                'DisplayName', sprintf('i=%g deg', i0));
        end
    
        xlabel('total satellites N_s');
        ylabel('max D_G^{min} under fixed i');
        title('Threshold diagnostic: D_G^{min} envelope versus N_s');
        legend('Location', 'eastoutside');
        grid on;
        box on;
        set(gca, 'FontSize', 13);
    end
    
    function fig = local_plot_transition_summary(T_trans)
        fig = figure('Color', 'w', 'Name', 'Stage05 Transition Summary', 'Position', [160 160 1100 700]);
    
        yyaxis left;
        plot(T_trans.i_deg, T_trans.frontier_Ns, '-o', 'LineWidth', 2.5, 'MarkerSize', 10);
        ylabel('minimum feasible N_s');
        ylim([max(0, min(T_trans.frontier_Ns)-10), max(T_trans.frontier_Ns)+10]);
    
        yyaxis right;
        plot(T_trans.i_deg, T_trans.frontier_D_G_min, '-s', 'LineWidth', 2.5, 'MarkerSize', 9);
        ylabel('D_G^{min} of frontier point');
    
        hold on;
        for k = 1:height(T_trans)
            if ~isnan(T_trans.frontier_Ns(k))
                yyaxis left;
                text(T_trans.i_deg(k)+0.3, T_trans.frontier_Ns(k)+1.0, ...
                    sprintf('(P=%g,T=%g)', T_trans.frontier_P(k), T_trans.frontier_T(k)), ...
                    'FontSize', 11, 'Color', [0.1 0.1 0.1]);
            end
        end
    
        xlabel('inclination i (deg)');
        title('Inclination-wise frontier summary');
        grid on;
        box on;
        set(gca, 'FontSize', 13);
    end
