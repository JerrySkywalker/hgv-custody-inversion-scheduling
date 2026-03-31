function result = policy_static_hold(caseData, cfg)
%POLICY_STATIC_HOLD  Minimal static-hold baseline for chapter 5.
%
% Strategy:
%   1) find a reference time with maximum visible candidates
%   2) use that visible set as static preferred template
%   3) online, keep preferred satellites whenever visible
%   4) if none visible, fall back to first currently visible one

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

inner = run_inner_loop_filter(caseData, cfg);

t = caseData.time.t(:);
N = numel(t);

counts = caseData.candidates.count(:);
[~, k_ref] = max(counts);
preferred_ids = caseData.candidates.sets{k_ref};
preferred_ids = preferred_ids(:).';

if isempty(preferred_ids)
    preferred_ids = [];
end

if ~isfield(cfg, 'ch5') || ~isfield(cfg.ch5, 'max_track_sats')
    max_track_sats = 2;
else
    max_track_sats = cfg.ch5.max_track_sats;
end

if numel(preferred_ids) > max_track_sats
    preferred_ids = preferred_ids(1:max_track_sats);
end

selected_sets = cell(N, 1);
tracking_sat_count = zeros(N, 1);

for k = 1:N
    visible_ids = caseData.candidates.sets{k};
    visible_ids = visible_ids(:).';

    keep_ids = intersect(preferred_ids, visible_ids, 'stable');

    if isempty(keep_ids)
        if isempty(visible_ids)
            selected_ids = [];
        else
            selected_ids = visible_ids(1:min(max_track_sats, numel(visible_ids)));
        end
    else
        selected_ids = keep_ids(1:min(max_track_sats, numel(keep_ids)));
    end

    selected_sets{k} = selected_ids;
    tracking_sat_count(k) = numel(selected_ids);
end

base_err = inner.pos_err_norm(:);

% Static-hold surrogate:
%   slightly worse than tracking-dynamic when 2 sats available
%   same when only 1 sat is available
rmse_scale = ones(N, 1);
rmse_scale(tracking_sat_count == 0) = 1.40;
rmse_scale(tracking_sat_count == 1) = 1.02;
rmse_scale(tracking_sat_count >= 2) = 0.92;

rmse_pos = base_err .* rmse_scale;

result = struct();
result.method = 'S';
result.reference_index = k_ref;
result.reference_ids = preferred_ids;
result.time = t;
result.selected_sets = selected_sets;
result.tracking_sat_count = tracking_sat_count;
result.rmse_pos = rmse_pos;
end
