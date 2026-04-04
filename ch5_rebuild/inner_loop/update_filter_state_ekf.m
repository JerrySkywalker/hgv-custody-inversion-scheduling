function upd = update_filter_state_ekf(pred, y_k, h_fun, H_fun, R)
%UPDATE_FILTER_STATE_EKF EKF measurement update.
%
% Inputs:
%   pred  : struct from predict_filter_state
%   y_k   : measurement vector
%   h_fun : handle, y_hat = h_fun(x)
%   H_fun : handle, H = H_fun(x)
%   R     : measurement noise covariance
%
% Outputs:
%   x_plus, P_plus, nu, S, K, y_hat

assert(isstruct(pred) && isfield(pred, 'x_minus') && isfield(pred, 'P_minus'), 'Invalid pred struct.');
assert(isa(h_fun, 'function_handle'), 'h_fun must be a function handle.');
assert(isa(H_fun, 'function_handle'), 'H_fun must be a function handle.');

x_minus = pred.x_minus(:);
P_minus = pred.P_minus;

y_k = y_k(:);
y_hat = h_fun(x_minus);
y_hat = y_hat(:);

H = H_fun(x_minus);
assert(size(H, 2) == numel(x_minus), 'Jacobian dimension mismatch.');
assert(size(H, 1) == numel(y_k), 'Measurement dimension mismatch.');
assert(all(size(R) == [numel(y_k) numel(y_k)]), 'R size mismatch.');

nu = y_k - y_hat;
S = H * P_minus * H.' + R;
S = 0.5 * (S + S.');

K = (P_minus * H.') / S;

x_plus = x_minus + K * nu;
I = eye(size(P_minus));
P_plus = (I - K * H) * P_minus * (I - K * H).' + K * R * K.';
P_plus = 0.5 * (P_plus + P_plus.');

upd = struct();
upd.x_plus = x_plus;
upd.P_plus = P_plus;
upd.nu = nu;
upd.S = S;
upd.K = K;
upd.y_hat = y_hat;
upd.H = H;
end
