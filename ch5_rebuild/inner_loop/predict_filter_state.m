function pred = predict_filter_state(filter_state, model, Q)
%PREDICT_FILTER_STATE Time update for the filter.
%
% Inputs:
%   filter_state.x_plus : posterior state at k
%   filter_state.P_plus : posterior covariance at k
%   model               : local DMD model
%   Q                   : process noise covariance
%
% Output struct fields:
%   x_minus, P_minus, F, Q

assert(isstruct(filter_state), 'filter_state must be a struct.');
assert(isfield(filter_state, 'x_plus') && isfield(filter_state, 'P_plus'), ...
    'filter_state must contain x_plus and P_plus.');
assert(isstruct(model) && isfield(model, 'A') && isfield(model, 'b'), 'Invalid model.');

x_plus = filter_state.x_plus(:);
P_plus = filter_state.P_plus;
nx = numel(x_plus);

assert(all(size(P_plus) == [nx nx]), 'P_plus size mismatch.');
assert(all(size(Q) == [nx nx]), 'Q size mismatch.');

F = model.A;
x_minus = propagate_state_koopman_dmd(model, x_plus);
P_minus = F * P_plus * F.' + Q;
P_minus = 0.5 * (P_minus + P_minus.');

pred = struct();
pred.x_minus = x_minus;
pred.P_minus = P_minus;
pred.F = F;
pred.Q = Q;
end
