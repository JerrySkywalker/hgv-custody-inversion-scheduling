function [score, aux] = score_pair_online_danger_weighted_gain(ch5case, selection_trace_prefix, pair_bank, pair, k_now, opts)
%SCORE_PAIR_ONLINE_DANGER_WEIGHTED_GAIN
% R8.5f.4b:
%   Threshold-crossing-oriented gain score.
%
% score =
%   sum_{u in affected windows} [
%       alpha * 1{lambda_base(u)<gamma && lambda_new(u)>=gamma}
%     + beta  * ((lambda_new(u)-lambda_base(u)) / (gamma-lambda_base(u)+eps))
%              * 1{lambda_base(u)<gamma}
%   ]
%   - eta_switch * 1{pair ~= prev_pair}

assert(isstruct(ch5case), 'ch5case must be struct.');
assert(iscell(selection_trace_prefix), 'selection_trace_prefix must be cell.');
assert(iscell(pair_bank), 'pair_bank must be cell.');
assert(isnumeric(pair) && numel(pair) >= 2, 'pair must be numeric length>=2.');
assert(isnumeric(k_now) && isscalar(k_now), 'k_now must be scalar.');

if nargin < 6 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'eta_switch'); opts.eta_switch = 1e6; end
if ~isfield(opts, 'lookahead_steps'); opts.lookahead_steps = []; end
if ~isfield(opts, 'alpha_cross'); opts.alpha_cross = 1e5; end
if ~isfield(opts, 'beta_margin'); opts.beta_margin = 1; end
if ~isfield(opts, 'eps_margin'); opts.eps_margin = 1e-6; end

[x_truth, sat_pos, gamma_req, W] = local_resolve_case_data(ch5case);
n_steps = size(x_truth,1);

if isempty(opts.lookahead_steps)
    lookahead_steps = W;
else
    lookahead_steps = opts.lookahead_steps;
end

prev_pair = [];
if k_now > 1 && numel(selection_trace_prefix) >= k_now-1
    prev_pair = local_get_pair(selection_trace_prefix{k_now-1});
end

J_new = local_build_J_pair_from_geometry( ...
    sat_pos(k_now,:,pair(1)), sat_pos(k_now,:,pair(2)), x_truth(k_now,1:3));

if isempty(prev_pair)
    switch_penalty = 0;
else
    switch_penalty = opts.eta_switch * double(any(prev_pair(:) ~= pair(:)));
end

u1 = k_now;
u2 = min(n_steps, k_now + lookahead_steps - 1);

gain_sum = 0;
cross_bonus_sum = 0;
margin_gain_sum = 0;

lambda_base_vec = NaN(u2-u1+1,1);
lambda_new_vec  = NaN(u2-u1+1,1);
cross_vec       = false(u2-u1+1,1);
margin_ratio_vec= zeros(u2-u1+1,1);

for uu = u1:u2
    Y_base = local_build_window_information(ch5case, selection_trace_prefix, uu, W);
    Y_new  = local_build_window_information_with_override(ch5case, selection_trace_prefix, uu, W, k_now, J_new);

    lambda_base = min(eig(0.5*(Y_base+Y_base.')));
    lambda_new  = min(eig(0.5*(Y_new +Y_new .')));

    idx = uu-u1+1;
    lambda_base_vec(idx) = lambda_base;
    lambda_new_vec(idx)  = lambda_new;

    is_danger = (lambda_base < gamma_req);
    is_cross_up = is_danger && (lambda_new >= gamma_req);

    cross_bonus = opts.alpha_cross * double(is_cross_up);

    if is_danger
        denom = max(gamma_req - lambda_base, opts.eps_margin);
        margin_ratio = (lambda_new - lambda_base) / denom;
    else
        margin_ratio = 0;
    end

    margin_gain = opts.beta_margin * margin_ratio;

    gain_sum = gain_sum + cross_bonus + margin_gain;
    cross_bonus_sum = cross_bonus_sum + cross_bonus;
    margin_gain_sum = margin_gain_sum + margin_gain;

    cross_vec(idx) = is_cross_up;
    margin_ratio_vec(idx) = margin_ratio;
end

score = gain_sum - switch_penalty;

aux = struct();
aux.gain_sum = gain_sum;
aux.cross_bonus_sum = cross_bonus_sum;
aux.margin_gain_sum = margin_gain_sum;
aux.switch_penalty = switch_penalty;
aux.lambda_base_vec = lambda_base_vec;
aux.lambda_new_vec = lambda_new_vec;
aux.cross_vec = cross_vec;
aux.margin_ratio_vec = margin_ratio_vec;
aux.J_pair = J_new;
end

function YW = local_build_window_information(ch5case, selection_trace_prefix, u, W)
[x_truth, sat_pos, ~, ~] = local_resolve_case_data(ch5case);
n_steps = size(x_truth,1);
u2 = min(n_steps, u + W - 1);

YW = zeros(3,3);
for t = u:u2
    pair_t = [];
    if t <= numel(selection_trace_prefix)
        pair_t = local_get_pair(selection_trace_prefix{t});
    end
    if isempty(pair_t)
        continue;
    end
    Jt = local_build_J_pair_from_geometry( ...
        sat_pos(t,:,pair_t(1)), sat_pos(t,:,pair_t(2)), x_truth(t,1:3));
    YW = YW + Jt;
end
YW = 0.5*(YW+YW.');
end

function YW = local_build_window_information_with_override(ch5case, selection_trace_prefix, u, W, k_override, J_override)
[x_truth, sat_pos, ~, ~] = local_resolve_case_data(ch5case);
n_steps = size(x_truth,1);
u2 = min(n_steps, u + W - 1);

YW = zeros(3,3);
for t = u:u2
    if t == k_override
        Jt = J_override;
    else
        pair_t = [];
        if t <= numel(selection_trace_prefix)
            pair_t = local_get_pair(selection_trace_prefix{t});
        end
        if isempty(pair_t)
            continue;
        end
        Jt = local_build_J_pair_from_geometry( ...
            sat_pos(t,:,pair_t(1)), sat_pos(t,:,pair_t(2)), x_truth(t,1:3));
    end
    YW = YW + Jt;
end
YW = 0.5*(YW+YW.');
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
