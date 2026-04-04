function W = compute_predicted_window_gramian(F_seq, x_seq, H_fun, R)
%COMPUTE_PREDICTED_WINDOW_GRAMIAN Dynamic finite-horizon local observability Gramian.
%
% Inputs:
%   F_seq : [nx x nx x L] local state transition Jacobians for each step
%   x_seq : [nx x L] predicted state sequence
%   H_fun : handle, H = H_fun(x)
%   R     : measurement covariance [ny x ny]
%
% Output:
%   W     : [nx x nx] dynamic local observability Gramian
%
% Definition:
%   W(k;L) = sum_{ell=0}^{L-1} Phi_{k+ell,k}' * H_{k+ell}' * R^{-1} * H_{k+ell} * Phi_{k+ell,k}
%
% where Phi_{k,k} = I and
%       Phi_{k+ell,k} = F_{k+ell-1} * ... * F_k, for ell >= 1.

assert(isnumeric(x_seq) && ismatrix(x_seq), 'x_seq must be a numeric matrix.');
assert(isnumeric(F_seq) && ndims(F_seq) == 3, 'F_seq must be a numeric 3D array.');
assert(isa(H_fun, 'function_handle'), 'H_fun must be a function handle.');
assert(isnumeric(R) && ismatrix(R), 'R must be a numeric matrix.');

[nx, L] = size(x_seq);
assert(size(F_seq,1) == nx && size(F_seq,2) == nx && size(F_seq,3) == L, ...
    'F_seq size must be [nx x nx x L].');

R_inv = inv(R);
W = zeros(nx, nx);

Phi = eye(nx); % Phi_{k,k}
for ell = 1:L
    if ell > 1
        Phi = F_seq(:,:,ell-1) * Phi;
    end

    x_now = x_seq(:, ell);
    H = H_fun(x_now);
    assert(size(H,2) == nx, 'H dimension mismatch.');

    W = W + Phi.' * H.' * R_inv * H * Phi;
end

W = 0.5 * (W + W.');
end
