function out = extract_worst_window_neighborhood(ch5case, selection_trace, tag, half_width)
%EXTRACT_WORST_WINDOW_NEIGHBORHOOD
% R8.6b:
%   Extract local neighborhood around the worst window for a policy.

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace), 'selection_trace must be cell.');
assert(isnumeric(half_width) && isscalar(half_width) && half_width >= 0, 'half_width invalid.');

wm = compute_worst_window_metrics_from_selection_trace(ch5case, selection_trace, tag);

idx0 = wm.summary.worst_window_index;
n_steps = wm.summary.n_steps;

k1 = max(1, idx0 - half_width);
k2 = min(n_steps, idx0 + half_width);
idx = (k1:k2).';

lambda_local = wm.lambda_series(k1:k2);
bubble_mask_local = wm.bubble_mask(k1:k2);
bubble_depth_local = wm.bubble_depth(k1:k2);

pair_a = NaN(numel(idx),1);
pair_b = NaN(numel(idx),1);

for ii = 1:numel(idx)
    rec = selection_trace{idx(ii)};
    if isstruct(rec) && isfield(rec, 'best_pair') && ~isempty(rec.best_pair) && numel(rec.best_pair) >= 2
        p = rec.best_pair(:).';
        pair_a(ii) = p(1);
        pair_b(ii) = p(2);
    end
end

local_table = table( ...
    idx, ...
    lambda_local, ...
    bubble_mask_local, ...
    bubble_depth_local, ...
    pair_a, ...
    pair_b, ...
    'VariableNames', { ...
        'step_index', ...
        'lambda_min_window', ...
        'bubble_mask', ...
        'bubble_depth', ...
        'pair_sat_1', ...
        'pair_sat_2'});

out = struct();
out.summary = wm.summary;
out.k1 = k1;
out.k2 = k2;
out.idx0 = idx0;
out.local_table = local_table;
out.lambda_local = lambda_local;
out.bubble_depth_local = bubble_depth_local;
out.pair_a = pair_a;
out.pair_b = pair_b;
out.wm = wm;
end
