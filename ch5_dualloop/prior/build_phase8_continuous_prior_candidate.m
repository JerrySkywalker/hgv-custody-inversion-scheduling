function cand = build_phase8_continuous_prior_candidate(caseData, selected_ids, k, cfg, g)
% 为 Phase08 continuous prior 构造真实 candidate 特征
%
% 当前只稳定提取三类真实量：
%   lambda_geom
%   crossing_angle_deg
%   baseline_km
%
% Bxy_cand / Ruse 在真实主链下暂未发现干净 local-frame 来源，
% 因此先置 NaN，让正式主链默认走 fragility-only。
%
% 输入:
%   caseData.truth.x / y / z
%   caseData.satbank.r_eci_km
%
% 输出:
%   cand.lambda_geom
%   cand.crossing_angle_deg
%   cand.baseline_km
%   cand.Bxy_cand
%   cand.Ruse

cand = struct();
cand.lambda_geom = g.lambda_min_geom;
cand.crossing_angle_deg = g.min_crossing_angle_deg;

cand.baseline_km = 600.0;
cand.Bxy_cand = NaN;
cand.Ruse = NaN;

if isempty(selected_ids)
    return;
end

% ------------------------------------------------
% 从 caseData.satbank.r_eci_km 提取当前时刻已选卫星位置
% 支持几种常见排列：
%   [Nt, Ns, 3]
%   [3, Ns, Nt]
%   [Nt, 3, Ns]
%   [Ns, Nt, 3]
% ------------------------------------------------
if ~isfield(caseData, 'satbank') || ~isfield(caseData.satbank, 'r_eci_km')
    return;
end

R = caseData.satbank.r_eci_km;
ids = selected_ids(:).';
pos = local_extract_sat_positions(R, k, ids);

if isempty(pos)
    return;
end

% baseline_km: 当前时刻 selected_ids 最大 pair 3D 距离
if size(pos,1) >= 2
    dmax = 0.0;
    for i = 1:size(pos,1)
        for j = i+1:size(pos,1)
            dmax = max(dmax, norm(pos(i,:) - pos(j,:)));
        end
    end
    cand.baseline_km = dmax;
else
    cand.baseline_km = 0.0;
end

% ------------------------------------------------
% 当前版本不对 Bxy_cand / Ruse 做伪估计
% 因为 truth 给的是 local x/y/z，而 satbank 只有 ECI，
% 直接混用会引入坐标系误差。
% 后续若需要 full prior，再补 satbank->local frame 投影。
% ------------------------------------------------
cand.Bxy_cand = NaN;
cand.Ruse = NaN;
end

function pos = local_extract_sat_positions(R, k, ids)
pos = [];

try
    sz = size(R);
    nd = ndims(R);

    if nd ~= 3
        return;
    end

    % Case 1: [Nt, Ns, 3]
    if sz(3) == 3
        if k <= sz(1) && max(ids) <= sz(2)
            tmp = squeeze(R(k, ids, :));
            if size(tmp,2) == 3
                pos = tmp;
                return;
            end
        end
    end

    % Case 2: [3, Ns, Nt]
    if sz(1) == 3
        if max(ids) <= sz(2) && k <= sz(3)
            tmp = squeeze(R(:, ids, k)).';
            if size(tmp,2) == 3
                pos = tmp;
                return;
            end
        end
    end

    % Case 3: [Nt, 3, Ns]
    if sz(2) == 3
        if k <= sz(1) && max(ids) <= sz(3)
            tmp = squeeze(R(k, :, ids)).';
            if size(tmp,2) == 3
                pos = tmp;
                return;
            end
        end
    end

    % Case 4: [Ns, Nt, 3]
    if sz(3) == 3
        if max(ids) <= sz(1) && k <= sz(2)
            tmp = squeeze(R(ids, k, :));
            if size(tmp,2) == 3
                pos = tmp;
                return;
            end
        end
    end

catch
    pos = [];
end
end
