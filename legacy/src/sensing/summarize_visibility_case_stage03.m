function s = summarize_visibility_case_stage03(vis_case, los_geom)
    %SUMMARIZE_VISIBILITY_CASE_STAGE03 Per-case visibility summary.
    
        s = struct();
        s.case_id = vis_case.case_id;
        s.family = vis_case.family;
        s.subfamily = vis_case.subfamily;
    
        s.num_time = numel(vis_case.t_s);
        s.mean_num_visible = mean(vis_case.num_visible, 'omitnan');
        s.max_num_visible = max(vis_case.num_visible);
        s.dual_coverage_ratio = mean(vis_case.dual_coverage_mask, 'omitnan');
    
        valid_idx = ~isnan(los_geom.min_crossing_angle_deg);
        if any(valid_idx)
            s.min_los_crossing_angle_deg = min(los_geom.min_crossing_angle_deg(valid_idx));
            s.mean_los_crossing_angle_deg = mean(los_geom.mean_crossing_angle_deg(valid_idx), 'omitnan');
        else
            s.min_los_crossing_angle_deg = NaN;
            s.mean_los_crossing_angle_deg = NaN;
        end
    end