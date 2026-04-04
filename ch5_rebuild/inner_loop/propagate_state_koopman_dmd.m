function x_pred = propagate_state_koopman_dmd(model, x_now)
%PROPAGATE_STATE_KOOPMAN_DMD One-step state propagation using fitted local linear model.
%
% Inputs:
%   model : struct from fit_local_dmd_operator
%   x_now : [nx x 1] current state
%
% Output:
%   x_pred : [nx x 1] predicted next state

assert(isstruct(model) && isfield(model, 'A') && isfield(model, 'b'), 'Invalid DMD model.');
assert(isnumeric(x_now) && isvector(x_now), 'x_now must be a numeric vector.');

x_now = x_now(:);
assert(size(model.A, 2) == numel(x_now), 'State dimension mismatch.');

x_pred = model.A * x_now + model.b;
end
