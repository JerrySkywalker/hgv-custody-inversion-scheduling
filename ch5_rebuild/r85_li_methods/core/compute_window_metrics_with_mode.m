function out = compute_window_metrics_with_mode(ch5case, selection_trace, tag, mode)
%COMPUTE_WINDOW_METRICS_WITH_MODE
% R8X.1:
%   Recompute lambda_min window series under different window semantics.
%
% mode:
%   'forward_truncated'  : current behavior, [k, min(k+W-1,n)]
%   'forward_full_only'  : only evaluate k with full forward window
%   'centered_full_only' : centered full window

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace), 'selection_trace must be cell.');
assert(ischar(mode) || isstring(mode), 'mode must be char/string.');

mode = char(string(mode));

[x_truth, sat_pos, gamma_req, W] = local_resolve_case_data(ch5case);
n_steps = size(x_truth,1);

lambda_series = NaN(n_steps,1);
bubble_mask = false(n_steps,1);
bubble_depth = zeros(n_steps,1);

for k = 1:n_steps
    [t1, t2, is_valid] = local_window_range(k, n_steps, W, mode);
    if ~is_valid
        continue;
    end

    YW = zeros(3,3);
    for t = t1:t2
        pair_t = [];
        if t <= numel(selection_trace)
            pair_t = local_get_pair(selection_trace{t});
        end
        if isempty(pair_t)
            continue;
        end
        Jt = local_build_J_pair_from_geometry( ...
            sat_pos(t,:,pair_t(1)), sat_pos(t,:,pair_t(2)), x_truth(t,1:3));
        YW = YW + Jt;
    end
    YW = 0.5*(YW+YW.');

    lam = min(eig(YW));
    lambda_series(k) = lam;

    if lam < gamma_req
        bubble_mask(k) = true;
        bubble_depth(k) = gamma_req - lam;
    end
end

valid_mask = ~isnan(lambda_series);
valid_lambda = lambda_series(valid_mask);
valid_bubble = bubble_mask(valid_mask);
valid_depth = bubble_depth(valid_mask);

assert(~isempty(valid_lambda), 'No valid windows under mode=%s', mode);

[min_lambda, idx_local] = min(valid_lambda);
valid_idx = find(valid_mask);
worst_window_index = valid_idx(idx_local);

mean_lambda = mean(valid_lambda, 'omitnan');
median_lambda = median(valid_lambda, 'omitnan');

longest_bubble_span = 0;
current_span = 0;
for k = 1:n_steps
    if valid_mask(k) && bubble_mask(k)
        current_span = current_span + 1;
        longest_bubble_span = max(longest_bubble_span, current_span);
    else
        current_span = 0;
    end
end

mean_bubble_depth = mean(valid_depth(valid_bubble), 'omitnan');
if isempty(mean_bubble_depth) || isnan(mean_bubble_depth)
    mean_bubble_depth = 0;
end

switch_count = local_count_switches(selection_trace);

summary = struct();
summary.tag = string(tag);
summary.mode = string(mode);
summary.n_steps = n_steps;
summary.n_valid_windows = sum(valid_mask);
summary.mean_lambda_min_window = mean_lambda;
summary.median_lambda_min_window = median_lambda;
summary.min_lambda_min_window = min_lambda;
summary.worst_window_index = worst_window_index;
summary.bubble_steps = sum(valid_bubble);
summary.bubble_time_s = sum(valid_bubble); % dt = 1 s
summary.max_bubble_depth = max(valid_depth);
summary.mean_bubble_depth = mean_bubble_depth;
summary.longest_bubble_span = longest_bubble_span;
summary.switch_count = switch_count;
summary.gamma_req = gamma_req;
summary.window_length_steps = W;

out = struct();
out.summary = summary;
out.lambda_series = lambda_series;
out.bubble_mask = bubble_mask;
out.bubble_depth = bubble_depth;
out.valid_mask = valid_mask;
end

function [x_truth, sat_pos, gamma_req, W] = local_resolve_case_data(ch5case)
assert(isfield(ch5case, 'truth') && isfield(ch5case.truth, 'X'), 'truth.X missing.');
assert(isfield(ch5case, 'satbank') && isfield(ch5case.satbank, 'r_eci_km'), 'satbank.r_eci_km missing.');
assert(isfield(ch5case, 'gamma_req'), 'gamma_req missing.');
assert(isfield(ch5case, 'window') && isfield(ch5case.window, 'length_steps'), 'window.length_steps missing.');

x_truth = ch5case.truth.X(:,1:6);
sat_pos = ch5case.satbank.r_eci_km;

if ndims(sat_pos) == 3 && size(sat_pos,2) == 3
elseif ndims(sat_pos) == 3 && size(sat_pos,1) == 3
    sat_pos = permute(sat_pos, [2 1 3]);
elseif ndims(sat_pos) == 3 && size(sat_pos,3) == 3
    sat_pos = permute(sat_pos, [1 3 2]);
else
    error('Unexpected satbank.r_eci_km shape.');
end

gamma_req = ch5case.gamma_req;
W = ch5case.window.length_steps;
end

function [t1, t2, is_valid] = local_window_range(k, n_steps, W, mode)
switch mode
    case 'forward_truncated'
        t1 = k;
        t2 = min(n_steps, k + W - 1);
        is_valid = (t1 <= t2);
    case 'forward_full_only'
        t1 = k;
        t2 = k + W - 1;
        is_valid = (t2 <= n_steps);
        if ~is_valid
            t1 = NaN; t2 = NaN;
        end
    case 'centered_full_only'
        half_left = floor((W-1)/2);
        half_right = W - 1 - half_left;
        t1 = k - half_left;
        t2 = k + half_right;
        is_valid = (t1 >= 1) && (t2 <= n_steps);
        if ~is_valid
            t1 = NaN; t2 = NaN;
        end
    otherwise
        error('Unsupported mode: %s', mode);
end
end

function J_pair = local_build_J_pair_from_geometry(rs1, rs2, rt)
u1 = (rt(:)-rs1(:)); u1 = u1 / norm(u1);
u2 = (rt(:)-rs2(:)); u2 = u2 / norm(u2);

H1 = eye(3) - u1*u1.';
H2 = eye(3) - u2*u2.';
R = 1e-4 * eye(3);

J_pair = H1.'*(R\H1) + H2.'*(R\H2);
J_pair = 0.5*(J_pair+J_pair.');
end

function p = local_get_pair(rec)
p = [];
if isstruct(rec) && isfield(rec, 'best_pair') && ~isempty(rec.best_pair)
    p = rec.best_pair(:).';
    if numel(p) >= 2
        p = p(1:2);
    else
        p = [];
    end
end
end

function c = local_count_switches(selection_trace)
c = 0;
prev = [];
for k = 1:numel(selection_trace)
    p = local_get_pair(selection_trace{k});
    if isempty(p)
        continue;
    end
    if ~isempty(prev) && any(prev(:) ~= p(:))
        c = c + 1;
    end
    prev = p;
end
end
