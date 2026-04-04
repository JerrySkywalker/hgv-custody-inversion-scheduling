function info_series_adj = apply_policy_to_info_series(ch5case, selection_trace)
%APPLY_POLICY_TO_INFO_SERIES  Apply minimal policy-dependent gain to info proxy.
%
% Current R4b note:
% This is still a proxy layer. It does not replace the future physical
% measurement model, but lets policy selections affect the resulting
% bubble metrics.

if nargin < 1 || isempty(ch5case)
    error('ch5case is required.');
end
if nargin < 2 || isempty(selection_trace)
    error('selection_trace is required.');
end

info_series = ch5case.info_series;
N = size(info_series, 3);

if numel(selection_trace) ~= N
    error('selection_trace length must equal number of time steps.');
end

theta_star = ch5case.theta;
Ns_star = theta_star.Ns;

info_series_adj = info_series;

for k = 1:N
    sel = selection_trace{k};
    theta_k = sel.theta;
    Ns_k = theta_k.Ns;

    gain = local_gain_from_theta(Ns_k, Ns_star, k, N);

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

function gain = local_gain_from_theta(Ns_k, Ns_star, k, N)
ratio = Ns_k / max(Ns_star, 1);

% Base gain from larger resource level.
gain = 1.0 + 0.55 * max(ratio - 1.0, 0);

% Give stronger effect near the natural valley, to emulate greedy rescue.
center = 0.62 * N;
width = 0.18 * N;
shape = exp(-((k - center)^2) / (2 * width^2));

gain = gain + 0.25 * max(ratio - 1.0, 0) * shape;
end
