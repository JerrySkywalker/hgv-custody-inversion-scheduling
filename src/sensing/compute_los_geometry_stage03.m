function los_geom = compute_los_geometry_stage03(vis_case, satbank)
    %COMPUTE_LOS_GEOMETRY_STAGE03 Compute LOS crossing-angle statistics.
    
        Nt = numel(vis_case.t_s);
        Ns = satbank.Ns;
    
        min_crossing_angle_deg = nan(Nt,1);
        mean_crossing_angle_deg = nan(Nt,1);
    
        for k = 1:Nt
            vis_idx = find(vis_case.visible_mask(k,:));
            if numel(vis_idx) < 2
                continue;
            end
    
            r_tgt = vis_case.r_tgt_eci_km(k,:);
            los_all = zeros(numel(vis_idx), 3);
    
            for j = 1:numel(vis_idx)
                s = vis_idx(j);
                r_sat = satbank.r_eci_km(k,:,s);
                los = r_sat - r_tgt;
                los_all(j,:) = los / norm(los);
            end
    
            angles = [];
            for a = 1:size(los_all,1)-1
                for b = a+1:size(los_all,1)
                    cval = dot(los_all(a,:), los_all(b,:));
                    cval = max(min(cval, 1), -1);
                    ang = acosd(cval);
                    angles(end+1,1) = ang; %#ok<AGROW>
                end
            end
    
            min_crossing_angle_deg(k) = min(angles);
            mean_crossing_angle_deg(k) = mean(angles);
        end
    
        los_geom = struct();
        los_geom.min_crossing_angle_deg = min_crossing_angle_deg;
        los_geom.mean_crossing_angle_deg = mean_crossing_angle_deg;
    end