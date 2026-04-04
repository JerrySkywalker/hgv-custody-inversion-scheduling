function W = compute_predicted_window_gramian(x_seq, H_fun, R)
%COMPUTE_PREDICTED_WINDOW_GRAMIAN Compute a predicted local window Gramian.
%
% Inputs:
%   x_seq : [nx x L] predicted state sequence over a window
%   H_fun : handle, H = H_fun(x)
%   R     : measurement covariance [ny x ny]
%
% Output:
%   W     : [nx x nx] local window Gramian
%
% Current minimal implementation:
%   W = sum(H' * inv(R) * H)

assert(isnumeric(x_seq) && ismatrix(x_seq), 'x_seq must be a numeric matrix.');
assert(isa(H_fun, 'function_handle'), 'H_fun must be a function handle.');
assert(isnumeric(R) && ismatrix(R), 'R must be a numeric matrix.');

[nx, L] = size(x_seq);
assert(L >= 1, 'Window length must be >= 1.');

W = zeros(nx, nx);
R_inv = inv(R);

for ell = 1:L
    x_now = x_seq(:, ell);
    H = H_fun(x_now);
    assert(size(H, 2) == nx, 'H dimension mismatch.');
    W = W + H.' * R_inv * H;
end

W = 0.5 * (W + W.');
end
