function summary_struct = summarize_trajectory_set(trajbank)
    %summarize_trajectory_set
    % Build structured summaries for Stage02 trajectory bank.
    %
    % This version avoids groupsummary for better MATLAB compatibility.
    % It provides:
    %   1) case_table
    %   2) family_summary
    %   3) heading_summary
    %   4) critical_summary
    
        % ------------------------------------------------------------
        % Collect all cases
        % ------------------------------------------------------------
        all_structs = [trajbank.nominal; trajbank.heading; trajbank.critical];
    
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
        case_ids = string(arrayfun(@(s) s.case.case_id, all_structs, 'UniformOutput', false));
        families = string(arrayfun(@(s) s.case.family, all_structs, 'UniformOutput', false));
        subfamilies = string(arrayfun(@(s) s.case.subfamily, all_structs, 'UniformOutput', false));
    
        heading_offsets = arrayfun(@(s) s.case.heading_offset_deg, all_structs);
        durations = arrayfun(@(s) s.summary.duration_s, all_structs);
        rmins = arrayfun(@(s) s.summary.r_min_to_center_km, all_structs);
        hmins = arrayfun(@(s) s.summary.h_range_km(1), all_structs);
        hmaxs = arrayfun(@(s) s.summary.h_range_km(2), all_structs);
        vmins = arrayfun(@(s) s.summary.v_range_mps(1), all_structs);
        vmaxs = arrayfun(@(s) s.summary.v_range_mps(2), all_structs);
        pass_flags = double(arrayfun(@(s) s.validation.pass, all_structs));
    
        % ------------------------------------------------------------
        % Force everything to column vectors
        % ------------------------------------------------------------
        case_ids = case_ids(:);
        families = families(:);
        subfamilies = subfamilies(:);
    
        heading_offsets = heading_offsets(:);
        durations = durations(:);
        rmins = rmins(:);
        hmins = hmins(:);
        hmaxs = hmaxs(:);
        vmins = vmins(:);
        vmaxs = vmaxs(:);
        pass_flags = pass_flags(:);
    
        % ------------------------------------------------------------
        % Build case table
        % ------------------------------------------------------------
        T = table(case_ids, families, subfamilies, heading_offsets, durations, ...
                  rmins, hmins, hmaxs, vmins, vmaxs, pass_flags);
    
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
        % Output struct
        % ------------------------------------------------------------
        summary_struct = struct();
        summary_struct.case_table = T;
        summary_struct.family_summary = family_summary;
        summary_struct.heading_summary = heading_summary;
        summary_struct.critical_summary = critical_summary;
    end
    
    % ========================================================================
    % Local helper: grouped summary
    % ========================================================================
    function S = local_group_summary(T, group_var_name)
    %LOCAL_GROUP_SUMMARY Robust grouped statistics table.
    
        groups = T.(group_var_name);
    
        % unique groups while preserving order
        [group_list, ~, group_idx] = unique(groups, 'stable');
        nG = numel(group_list);
    
        % preallocate
        group_value = cell(nG,1);
        N = zeros(nG,1);
    
        dur_mean = zeros(nG,1); dur_min = zeros(nG,1); dur_max = zeros(nG,1);
        rmin_mean = zeros(nG,1); rmin_min = zeros(nG,1); rmin_max = zeros(nG,1);
        hmin_mean = zeros(nG,1); hmin_min = zeros(nG,1); hmin_max = zeros(nG,1);
        hmax_mean = zeros(nG,1); hmax_min = zeros(nG,1); hmax_max = zeros(nG,1);
        vmin_mean = zeros(nG,1); vmin_min = zeros(nG,1); vmin_max = zeros(nG,1);
        vmax_mean = zeros(nG,1); vmax_min = zeros(nG,1); vmax_max = zeros(nG,1);
        pass_rate = zeros(nG,1);
    
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
                % fallback
                group_value{i} = char(string(gi));
            end
    
            N(i) = sum(idx);
    
            dur_mean(i) = mean(T.durations(idx), 'omitnan');
            dur_min(i)  = min(T.durations(idx));
            dur_max(i)  = max(T.durations(idx));
    
            rmin_mean(i) = mean(T.rmins(idx), 'omitnan');
            rmin_min(i)  = min(T.rmins(idx));
            rmin_max(i)  = max(T.rmins(idx));
    
            hmin_mean(i) = mean(T.hmins(idx), 'omitnan');
            hmin_min(i)  = min(T.hmins(idx));
            hmin_max(i)  = max(T.hmins(idx));
    
            hmax_mean(i) = mean(T.hmaxs(idx), 'omitnan');
            hmax_min(i)  = min(T.hmaxs(idx));
            hmax_max(i)  = max(T.hmaxs(idx));
    
            vmin_mean(i) = mean(T.vmins(idx), 'omitnan');
            vmin_min(i)  = min(T.vmins(idx));
            vmin_max(i)  = max(T.vmins(idx));
    
            vmax_mean(i) = mean(T.vmaxs(idx), 'omitnan');
            vmax_min(i)  = min(T.vmaxs(idx));
            vmax_max(i)  = max(T.vmaxs(idx));
    
            pass_rate(i) = mean(T.pass_flags(idx), 'omitnan');
        end
    
        % Convert grouping variable to proper output format
        if isnumeric(group_list)
            group_value = cell2mat(group_value);
        else
            group_value = string(group_value);
        end
    
        S = table(group_value, N, ...
            dur_mean, dur_min, dur_max, ...
            rmin_mean, rmin_min, rmin_max, ...
            hmin_mean, hmin_min, hmin_max, ...
            hmax_mean, hmax_min, hmax_max, ...
            vmin_mean, vmin_min, vmin_max, ...
            vmax_mean, vmax_min, vmax_max, ...
            pass_rate);
    end

