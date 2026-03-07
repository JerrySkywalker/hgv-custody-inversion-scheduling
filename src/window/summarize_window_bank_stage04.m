function summary_struct = summarize_window_bank_stage04(winbank)
    %SUMMARIZE_WINDOW_BANK_STAGE04
    % Build structured summaries for Stage04 window-spectrum results.
    %
    % Outputs:
    %   summary_struct.case_table
    %   summary_struct.family_summary
    %   summary_struct.heading_summary
    %   summary_struct.critical_summary
    
        all_structs = [winbank.nominal; winbank.heading; winbank.critical];
    
        if isempty(all_structs)
            summary_struct = struct();
            summary_struct.case_table = table();
            summary_struct.family_summary = table();
            summary_struct.heading_summary = table();
            summary_struct.critical_summary = table();
            return;
        end
    
        % ------------------------------------------------------------
        % Build raw columns
        % ------------------------------------------------------------
        case_ids = string(arrayfun(@(s) s.case_id, all_structs, 'UniformOutput', false));
        families = string(arrayfun(@(s) s.summary.family, all_structs, 'UniformOutput', false));
        subfamilies = string(arrayfun(@(s) s.summary.subfamily, all_structs, 'UniformOutput', false));
    
        lambda_worst = arrayfun(@(s) s.summary.lambda_min_worst, all_structs);
        lambda_mean  = arrayfun(@(s) s.summary.lambda_min_mean, all_structs);
        lambda_best  = arrayfun(@(s) s.summary.lambda_min_best, all_structs);
        t0_worst     = arrayfun(@(s) s.summary.t0_worst_s, all_structs);
    
        % Recover heading offset from case_id if possible
        heading_offsets = nan(numel(all_structs),1);
        for k = 1:numel(all_structs)
            cid = char(case_ids(k));
            tok = regexp(cid, '^H\d+_([+-]\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                heading_offsets(k) = str2double(tok{1});
            elseif ~isempty(regexp(cid, '^H\d+_\+00$', 'once'))
                heading_offsets(k) = 0;
            end
        end
    
        % ------------------------------------------------------------
        % Force all variables to column vectors
        % ------------------------------------------------------------
        case_ids = case_ids(:);
        families = families(:);
        subfamilies = subfamilies(:);
    
        heading_offsets = heading_offsets(:);
        lambda_worst = lambda_worst(:);
        lambda_mean = lambda_mean(:);
        lambda_best = lambda_best(:);
        t0_worst = t0_worst(:);
    
        % ------------------------------------------------------------
        % Build case table
        % ------------------------------------------------------------
        T = table(case_ids, families, subfamilies, heading_offsets, ...
                  lambda_worst, lambda_mean, lambda_best, t0_worst);
    
        % ------------------------------------------------------------
        % Summaries
        % ------------------------------------------------------------
        family_summary = local_group_summary(T, 'families');
    
        idx_heading = strcmp(string(T.families), "heading");
        T_heading = T(idx_heading, :);
        if ~isempty(T_heading)
            heading_summary = local_group_summary(T_heading, 'heading_offsets');
        else
            heading_summary = table();
        end
    
        idx_critical = strcmp(string(T.families), "critical");
        T_critical = T(idx_critical, :);
        if ~isempty(T_critical)
            critical_summary = local_group_summary(T_critical, 'subfamilies');
        else
            critical_summary = table();
        end
    
        % ------------------------------------------------------------
        % Output
        % ------------------------------------------------------------
        summary_struct = struct();
        summary_struct.case_table = T;
        summary_struct.family_summary = family_summary;
        summary_struct.heading_summary = heading_summary;
        summary_struct.critical_summary = critical_summary;
    end
    
    % ========================================================================
    % Local helper
    % ========================================================================
    function S = local_group_summary(T, group_var_name)
    
        groups = T.(group_var_name);
        [group_list, ~, group_idx] = unique(groups, 'stable');
        nG = numel(group_list);
    
        group_value = cell(nG,1);
        N = zeros(nG,1);
    
        lambda_worst_mean = zeros(nG,1);
        lambda_worst_min  = zeros(nG,1);
        lambda_worst_max  = zeros(nG,1);
    
        lambda_mean_mean = zeros(nG,1);
        lambda_mean_min  = zeros(nG,1);
        lambda_mean_max  = zeros(nG,1);
    
        lambda_best_mean = zeros(nG,1);
        lambda_best_min  = zeros(nG,1);
        lambda_best_max  = zeros(nG,1);
    
        t0_worst_mean = zeros(nG,1);
        t0_worst_min  = zeros(nG,1);
        t0_worst_max  = zeros(nG,1);
    
        for i = 1:nG
            idx = (group_idx == i);
            gi = group_list(i);
    
            if isstring(gi)
                group_value{i} = char(gi);
            elseif ischar(gi)
                group_value{i} = gi;
            elseif isnumeric(gi)
                group_value{i} = gi;
            else
                group_value{i} = char(string(gi));
            end
    
            N(i) = sum(idx);
    
            lambda_worst_mean(i) = mean(T.lambda_worst(idx), 'omitnan');
            lambda_worst_min(i)  = min(T.lambda_worst(idx));
            lambda_worst_max(i)  = max(T.lambda_worst(idx));
    
            lambda_mean_mean(i) = mean(T.lambda_mean(idx), 'omitnan');
            lambda_mean_min(i)  = min(T.lambda_mean(idx));
            lambda_mean_max(i)  = max(T.lambda_mean(idx));
    
            lambda_best_mean(i) = mean(T.lambda_best(idx), 'omitnan');
            lambda_best_min(i)  = min(T.lambda_best(idx));
            lambda_best_max(i)  = max(T.lambda_best(idx));
    
            t0_worst_mean(i) = mean(T.t0_worst(idx), 'omitnan');
            t0_worst_min(i)  = min(T.t0_worst(idx));
            t0_worst_max(i)  = max(T.t0_worst(idx));
        end
    
        if isnumeric(group_list)
            group_value = cell2mat(group_value);
        else
            group_value = string(group_value);
        end
    
        S = table(group_value, N, ...
            lambda_worst_mean, lambda_worst_min, lambda_worst_max, ...
            lambda_mean_mean, lambda_mean_min, lambda_mean_max, ...
            lambda_best_mean, lambda_best_min, lambda_best_max, ...
            t0_worst_mean, t0_worst_min, t0_worst_max);
    end