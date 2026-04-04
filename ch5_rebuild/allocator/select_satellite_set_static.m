function static_pair = select_satellite_set_static(cfg, truth, satbank, candidates)
%SELECT_SATELLITE_SET_STATIC
% Select one fixed double-satellite pair for the whole experiment.
%
% Strategy:
%   among all pairs that ever appear, choose the pair maximizing the
%   accumulated trace(J_pair) over all time steps where it is visible.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(true);
end
if nargin < 2 || isempty(truth)
    truth = build_ch5r_truth_from_stage02_engine(cfg);
end
if nargin < 3 || isempty(satbank)
    satbank = build_ch5r_satbank_from_stage03_engine(cfg, truth);
end
if nargin < 4 || isempty(candidates)
    candidates = build_ch5r_candidates(cfg, truth, satbank);
end

sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;
Nt = numel(candidates.pair_bank);

score_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
count_map = containers.Map('KeyType', 'char', 'ValueType', 'double');

for k = 1:Nt
    pair_list = candidates.pair_bank{k};
    if isempty(pair_list)
        continue;
    end

    r_tgt = truth.r_eci_km(k, :);

    for idx = 1:size(pair_list, 1)
        pair = pair_list(idx, :);
        key = sprintf('%d_%d', pair(1), pair(2));

        r_sat_pair = [
            squeeze(satbank.r_eci_km(k, :, pair(1)));
            squeeze(satbank.r_eci_km(k, :, pair(2)))
        ];

        J = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);
        s = trace(J);

        if ~isKey(score_map, key)
            score_map(key) = 0;
            count_map(key) = 0;
        end

        score_map(key) = score_map(key) + s;
        count_map(key) = count_map(key) + 1;
    end
end

keys_list = keys(score_map);
assert(~isempty(keys_list), 'No visible double-satellite pair found in the whole horizon.');

best_key = '';
best_score = -inf;
best_count = -inf;

for i = 1:numel(keys_list)
    key = keys_list{i};
    s = score_map(key);
    c = count_map(key);

    % Prefer larger cumulative score; use visibility count as tie-breaker.
    if (s > best_score) || (abs(s - best_score) < 1e-12 && c > best_count)
        best_key = key;
        best_score = s;
        best_count = c;
    end
end

parts = sscanf(best_key, '%d_%d');
static_pair = parts(:).';
assert(numel(static_pair) == 2, 'Invalid fixed pair decoding.');
end
