function summary_struct = summarize_visibility_bank_stage03(visbank)
    %SUMMARIZE_VISIBILITY_BANK_STAGE03 Group visibility summaries by family.
    
        all_structs = [visbank.nominal; visbank.heading; visbank.critical];
    
        case_ids = string(arrayfun(@(s) s.case_id, all_structs, 'UniformOutput', false)).';
        families = string(arrayfun(@(s) s.family, all_structs, 'UniformOutput', false)).';
        subfamilies = string(arrayfun(@(s) s.subfamily, all_structs, 'UniformOutput', false)).';
        mean_num_visible = arrayfun(@(s) s.summary.mean_num_visible, all_structs).';
        dual_coverage_ratio = arrayfun(@(s) s.summary.dual_coverage_ratio, all_structs).';
        min_los_crossing_angle_deg = arrayfun(@(s) s.summary.min_los_crossing_angle_deg, all_structs).';
        mean_los_crossing_angle_deg = arrayfun(@(s) s.summary.mean_los_crossing_angle_deg, all_structs).';
    
        T = table(case_ids, families, subfamilies, mean_num_visible, ...
                  dual_coverage_ratio, min_los_crossing_angle_deg, ...
                  mean_los_crossing_angle_deg);
    
        summary_struct = struct();
        summary_struct.case_table = T;
    end