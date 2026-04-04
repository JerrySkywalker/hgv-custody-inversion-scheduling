function [info_series_adj, gain_trace] = apply_policy_to_info_series(ch5case, selection_trace, cfg)
%APPLY_POLICY_TO_INFO_SERIES  Apply tunable policy-dependent gain to info proxy.

if nargin < 1 || isempty(ch5case)
    error('ch5case is required.');
end
if nargin < 2 || isempty(selection_trace)
    error('selection_trace is required.');
end
if nargin < 3 || isempty(cfg)
    cfg = default_ch5r_params();
end

info_series = ch5case.info_series;
N = size(info_series, 3);

if numel(selection_trace) ~= N
    error('selection_trace length must equal number of time steps.');
end

theta_star = ch5case.theta;
Ns_star = theta_star.Ns;

r4 = cfg.ch5r.r4;

info_series_adj = info_series;
gain_trace = zeros(N,1);

for k = 1:N
    sel = selection_trace{k};
    theta_k = sel.theta;
    Ns_k = theta_k.Ns;

    gain = local_gain_from_theta(Ns_k, Ns_star, k, N, r4);
    gain_trace(k) = gain;

    Yk = info_series(:,:,k);
    Yk = gain * Yk;
    Yk = 0.5 * (Yk + Yk.');

    mineig = min(eig(Yk));
    if mineig <= 0
        Yk = Yk + (abs(mineig) + 1e-6) * eye(size(Yk,1));
    end

    info_series_adj(:,:,k) = Yk;
end
end

function gain = local_gain_from_theta(Ns_k, Ns_star, k, N, r4)
ratio = Ns_k / max(Ns_star, 1);

gain = 1.0 + r4.gain_resource_coeff * max(ratio - 1.0, 0);

center = 0.62 * N;
width = 0.18 * N;
shape = exp(-((k - center)^2) / (2 * width^2));

gain = gain + r4.gain_shape_coeff * max(ratio - 1.0, 0) * shape;
end
