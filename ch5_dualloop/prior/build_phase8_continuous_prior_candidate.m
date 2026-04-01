function cand = build_phase8_continuous_prior_candidate(caseData, selected_ids, k, cfg, g)
% 为 continuous prior 构造 candidate 特征
%
% 输出字段：
%   lambda_geom
%   baseline_km
%   crossing_angle_deg
%   Bxy_cand
%   Ruse

cand = struct();

cand.lambda_geom = g.lambda_min_geom;
cand.crossing_angle_deg = g.min_crossing_angle_deg;

% --- baseline_km: 用已选集合在当前时刻的最大 pair baseline 近似 ---
cand.baseline_km = 0.0;
cand.Bxy_cand = 0.0;
cand.Ruse = 0.0;

if isempty(selected_ids)
    return;
end

if isfield(caseData, 'sat_states') && ndims(caseData.sat_states) >= 3
    % 期望 sat_states(k, sid, 1:3)
    ids = selected_ids(:).';
    pos = zeros(numel(ids), 3);
    ok = true;
    for i = 1:numel(ids)
        sid = ids(i);
        try
            pos(i,:) = squeeze(caseData.sat_states(k, sid, 1:3));
        catch
            ok = false;
            break;
        end
    end
    if ok
        if size(pos,1) >= 2
            dmax = 0.0;
            for i = 1:size(pos,1)
                for j = i+1:size(pos,1)
                    dmax = max(dmax, norm(pos(i,:) - pos(j,:)));
                end
            end
            cand.baseline_km = dmax;
        elseif size(pos,1) == 1
            cand.baseline_km = 0.0;
        end
    end
end

% --- Ruse / Bxy_cand: 用目标当前位置到已选卫星的平均/最大平面距离近似 ---
if isfield(caseData, 'target_states') && ndims(caseData.target_states) >= 2 && ...
   isfield(caseData, 'sat_states') && ndims(caseData.sat_states) >= 3

    try
        tgt = squeeze(caseData.target_states(k, 1:3)).';
        ids = selected_ids(:).';
        rxy = zeros(numel(ids),1);
        for i = 1:numel(ids)
            sid = ids(i);
            sat = squeeze(caseData.sat_states(k, sid, 1:3)).';
            rxy(i) = norm((sat(1:2) - tgt(1:2)));
        end
        if ~isempty(rxy)
            cand.Ruse = max(rxy);
            cand.Bxy_cand = mean(rxy);
        end
    catch
        % keep defaults
    end
end

% fallback: 避免零值导致代价失真
if cand.baseline_km <= 0
    cand.baseline_km = 600;
end
if cand.Bxy_cand <= 0
    cand.Bxy_cand = 100;
end
if cand.Ruse <= 0
    cand.Ruse = 200;
end
end
