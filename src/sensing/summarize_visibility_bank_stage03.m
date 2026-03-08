function summary_struct = summarize_visibility_bank_stage03(visbank)
    %SUMMARIZE_VISIBILITY_BANK_STAGE03
    % Build case-level summary table from current Stage03 visbank structure.
    %
    % Output:
    %   summary_struct.case_table   : N_case x 7 table
    
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
            s = all_structs(i);
    
            % basic identifiers
            case_ids(i) = string(s.case_id);
            families(i) = string(s.family);
            subfamilies(i) = string(s.subfamily);
    
            % summary metrics
            mean_num_visible(i) = s.summary.mean_num_visible;
            dual_coverage_ratio(i) = s.summary.dual_coverage_ratio;
            min_los_crossing_angle_deg(i) = s.summary.min_los_crossing_angle_deg;
            mean_los_crossing_angle_deg(i) = s.summary.mean_los_crossing_angle_deg;
        end
    
        case_table = table( ...
            case_ids, ...
            families, ...
            subfamilies, ...
            mean_num_visible, ...
            dual_coverage_ratio, ...
            min_los_crossing_angle_deg, ...
            mean_los_crossing_angle_deg);
    
        summary_struct = struct();
        summary_struct.case_table = case_table;
    end