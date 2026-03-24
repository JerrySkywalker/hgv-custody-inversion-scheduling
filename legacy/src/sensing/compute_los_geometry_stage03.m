function los_geom = compute_los_geometry_stage03(vis_case, satbank)
    %COMPUTE_LOS_GEOMETRY_STAGE03 Compute LOS crossing-angle statistics.
    
        Nt = numel(vis_case.t_s);
        Ns = satbank.Ns;
        min_crossing_angle_deg = nan(Nt,1);
        mean_crossing_angle_deg = nan(Nt,1);

        r_sat_eci_km = permute(satbank.r_eci_km(1:Nt,:,:), [1, 3, 2]);
        r_tgt_batch_km = reshape(vis_case.r_tgt_eci_km, [Nt, 1, 3]);
        los_all = r_sat_eci_km - r_tgt_batch_km;
        los_norm = sqrt(sum(los_all.^2, 3));
        los_unit = los_all ./ max(los_norm, eps);

        for k = 1:Nt
            vis_idx = vis_case.visible_mask(k,:);
            if nnz(vis_idx) < 2
                continue;
            end

            los_vis = reshape(los_unit(k, vis_idx, :), [], 3);
            gram = los_vis * los_vis.';
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
