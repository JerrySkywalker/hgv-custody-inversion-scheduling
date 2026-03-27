function s = summarize_single_trajectory(case_i, traj, val)
    %summarize_single_trajectory Build concise summary for logs/debug.
    
        s = struct();
        s.case_id = case_i.case_id;
        s.family = case_i.family;
        s.subfamily = case_i.subfamily;
        s.heading_deg = case_i.heading_deg;
    
        s.num_steps = val.num_steps;
        s.duration_s = val.duration_s;
        s.h_range_km = [val.h_min_km, val.h_max_km];
        s.v_range_mps = [val.v_min_mps, val.v_max_mps];
        s.r_min_to_center_km = val.r_min_to_center_km;
        s.final_xy_km = traj.xy_km(end,:);
        s.pass = val.pass;
        s.fail_reasons = val.fail_reasons;
    end

