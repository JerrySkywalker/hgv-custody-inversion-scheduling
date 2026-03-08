function summary_struct = summarize_visibility_bank_stage03_eci(visbank)
    %SUMMARIZE_VISIBILITY_BANK_STAGE03_ECI
    % Build case-level summary table from current visbank structure.
    
        all_structs = [visbank.nominal; visbank.heading; visbank.critical];
    
        n = numel(all_structs);
    
        case_ids = strings(n,1);
        families = strings(n,1);
        subfamilies = strings(n,1);
        mean_num_visible = nan(n,1);
        dual_coverage_ratio = nan(n,1);
        min_los_crossing_angle_deg = nan(n,1);
        mean_los_crossing_angle_deg = nan(n,1);
    
        for i = 1:n
            c = all_structs(i).case;
            v = all_structs(i).vis;
    
            case_ids(i) = string(c.case_id);
            families(i) = string(c.family);
            subfamilies(i) = string(c.subfamily);
    
            mean_num_visible(i) = v.mean_vis;
            dual_coverage_ratio(i) = v.dual_ratio;
            min_los_crossing_angle_deg(i) = v.min_crossing_deg;
    
            valid_idx = ~isnan(v.best_crossing_deg);
            if any(valid_idx)
                mean_los_crossing_angle_deg(i) = mean(v.best_crossing_deg(valid_idx), 'omitnan');
            end
        end
    
        T = table(case_ids, families, subfamilies, mean_num_visible, ...
                  dual_coverage_ratio, min_los_crossing_angle_deg, ...
                  mean_los_crossing_angle_deg);
    
        summary_struct = struct();
        summary_struct.case_table = T;
    end