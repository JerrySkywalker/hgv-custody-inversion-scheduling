function los_geom = compute_los_geometry_stage03(vis_case, satbank)
    %COMPUTE_LOS_GEOMETRY_STAGE03 Compute LOS crossing-angle statistics.
    
        Nt = numel(vis_case.t_s);
        min_crossing_angle_deg = nan(Nt,1);
        mean_crossing_angle_deg = nan(Nt,1);
    
        for k = 1:Nt
            vis_idx = find(vis_case.visible_mask(k,:));
            if numel(vis_idx) < 2
                continue;
            end
    
            r_tgt = vis_case.r_tgt_eci_km(k,:);
            r_sat_vis = squeeze(satbank.r_eci_km(k,:,vis_idx)).';
            los_all = r_sat_vis - r_tgt;
            los_all = los_all ./ max(sqrt(sum(los_all.^2, 2)), eps);

            gram = los_all * los_all.';
            gram = min(max(gram, -1), 1);
            pair_mask = triu(true(size(gram)), 1);
            angles = acosd(gram(pair_mask));

            min_crossing_angle_deg(k) = min(angles);
            mean_crossing_angle_deg(k) = mean(angles);
        end
    
        los_geom = struct();
        los_geom.min_crossing_angle_deg = min_crossing_angle_deg;
        los_geom.mean_crossing_angle_deg = mean_crossing_angle_deg;
    end
