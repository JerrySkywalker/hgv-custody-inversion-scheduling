function summary_struct = summarize_window_margin_bank_stage04(winbank, cfg)
    %SUMMARIZE_WINDOW_MARGIN_BANK_STAGE04
    % Summarize D_G and pass/fail statistics for Stage04G.7
    
        all_structs = [winbank.nominal; winbank.heading; winbank.critical];
    
        if isempty(all_structs)
            summary_struct = struct();
            summary_struct.case_table = table();
            summary_struct.family_summary = table();
            summary_struct.heading_summary = table();
            summary_struct.critical_summary = table();
            return;
        end
    
        n = numel(all_structs);
    
        case_ids = strings(n,1);
        families = strings(n,1);
        subfamilies = strings(n,1);
        heading_offsets = nan(n,1);
    
        gamma_req = zeros(n,1);
        lambda_worst = zeros(n,1);
        D_G = zeros(n,1);
        pass_flag = zeros(n,1);
        t0_worst = zeros(n,1);
    
        for k = 1:n
            wc = all_structs(k).window_case;
            m = evaluate_window_margin_stage04(wc, cfg);
    
            case_ids(k) = string(m.case_id);
            families(k) = string(m.family);
            subfamilies(k) = string(m.subfamily);
    
            cid = char(case_ids(k));
            tok = regexp(cid, '^H\d+_([+-]\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                heading_offsets(k) = str2double(tok{1});
            elseif ~isempty(regexp(cid, '^H\d+_\+00$', 'once'))
                heading_offsets(k) = 0;
            end
    
            gamma_req(k) = m.gamma_req;
            lambda_worst(k) = m.lambda_worst;
            D_G(k) = m.D_G;
            pass_flag(k) = double(m.pass_flag);
            t0_worst(k) = m.t0_worst_s;
        end
    
        T = table(case_ids, families, subfamilies, heading_offsets, ...
                  gamma_req, lambda_worst, D_G, pass_flag, t0_worst);
    
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
    
        summary_struct = struct();
        summary_struct.case_table = T;
        summary_struct.family_summary = family_summary;
        summary_struct.heading_summary = heading_summary;
        summary_struct.critical_summary = critical_summary;
    end
    
    function S = local_group_summary(T, group_var_name)
    
        groups = T.(group_var_name);
        [group_list, ~, group_idx] = unique(groups, 'stable');
        nG = numel(group_list);
    
        group_value = cell(nG,1);
        N = zeros(nG,1);
    
        gamma_req_mean = zeros(nG,1);
    
        lambda_worst_mean = zeros(nG,1);
        lambda_worst_min  = zeros(nG,1);
        lambda_worst_max  = zeros(nG,1);
    
        D_G_mean = zeros(nG,1);
        D_G_min  = zeros(nG,1);
        D_G_max  = zeros(nG,1);
    
        pass_ratio = zeros(nG,1);
    
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
    
            gamma_req_mean(i) = mean(T.gamma_req(idx), 'omitnan');
    
            lambda_worst_mean(i) = mean(T.lambda_worst(idx), 'omitnan');
            lambda_worst_min(i)  = min(T.lambda_worst(idx));
            lambda_worst_max(i)  = max(T.lambda_worst(idx));
    
            D_G_mean(i) = mean(T.D_G(idx), 'omitnan');
            D_G_min(i)  = min(T.D_G(idx));
            D_G_max(i)  = max(T.D_G(idx));
    
            pass_ratio(i) = mean(T.pass_flag(idx), 'omitnan');
    
            t0_worst_mean(i) = mean(T.t0_worst(idx), 'omitnan');
            t0_worst_min(i)  = min(T.t0_worst(idx));
            t0_worst_max(i)  = max(T.t0_worst(idx));
        end
    
        if isnumeric(group_list)
            group_value = cell2mat(group_value);
        else
            group_value = string(group_value);
        end
    
        S = table(group_value, N, gamma_req_mean, ...
            lambda_worst_mean, lambda_worst_min, lambda_worst_max, ...
            D_G_mean, D_G_min, D_G_max, ...
            pass_ratio, ...
            t0_worst_mean, t0_worst_min, t0_worst_max);
    end