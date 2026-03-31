function result = policy_static_hold(caseData, cfg)
%POLICY_STATIC_HOLD  Static-hold baseline for chapter 5.
%
% Phase 4 baseline:
%   - choose an initial held satellite set at the first visible time
%   - do not re-optimize online
%   - at each time, only satellites still visible in the held set remain active

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

inner = run_inner_loop_filter(caseData, cfg);

t = caseData.time.t(:);
N = numel(t);

if ~isfield(cfg, 'ch5') || ~isfield(cfg.ch5, 'max_track_sats')
    max_track_sats = 2;
else
    max_track_sats = cfg.ch5.max_track_sats;
end

held_ids = [];
for k0 = 1:N
    vis0 = caseData.candidates.sets{k0};
    if ~isempty(vis0)
        held_ids = vis0(1:min(max_track_sats, numel(vis0)));
        break;
    end
end

selected_sets = cell(N, 1);
tracking_sat_count = zeros(N, 1);

for k = 1:N
    vis_ids = caseData.candidates.sets{k};
    selected_ids = intersect(held_ids, vis_ids, 'stable');
    selected_sets{k} = selected_ids;
    tracking_sat_count(k) = numel(selected_ids);
end

base_err = inner.pos_err_norm(:);

% Static hold should be weaker than dynamic tracking:
% 0 sat -> worst
% 1 sat -> slightly worse than T
% 2 sat -> still a bit worse than T because it cannot adapt
rmse_scale = ones(N, 1);
rmse_scale(tracking_sat_count == 0) = 1.60;
rmse_scale(tracking_sat_count == 1) = 1.10;
rmse_scale(tracking_sat_count >= 2) = 0.92;

rmse_pos = base_err .* rmse_scale;

result = struct();
result.method = 'S';
result.held_ids = held_ids;
result.time = t;
result.selected_sets = selected_sets;
result.tracking_sat_count = tracking_sat_count;
result.rmse_pos = rmse_pos;
end
