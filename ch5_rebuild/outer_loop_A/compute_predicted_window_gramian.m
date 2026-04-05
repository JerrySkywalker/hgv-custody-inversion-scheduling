function W = compute_predicted_window_gramian(F_seq, x_seq, H_fun, R)
%COMPUTE_PREDICTED_WINDOW_GRAMIAN Compute predicted finite-window information Gramian.
%
% Compatible inputs:
%   F_seq : [nx x nx] or [nx x nx x L]
%   x_seq : [nx x L]
%
% Output:
%   W     : [nx x nx]
%
% Definition:
%   W = sum_{ell=1}^L F_ell' * H_ell' * R^{-1} * H_ell * F_ell

assert(isnumeric(F_seq) && ~isempty(F_seq), 'F_seq must be numeric and non-empty.');
assert(isnumeric(x_seq) && ismatrix(x_seq) && ~isempty(x_seq), 'x_seq must be a non-empty numeric matrix.');
assert(isa(H_fun, 'function_handle'), 'H_fun must be a function handle.');
assert(isnumeric(R) && ismatrix(R) && size(R,1) == size(R,2), 'R must be a square numeric matrix.');

% Normalize F_seq to 3D array [nx x nx x L]
szF = size(F_seq);
if ismatrix(F_seq)
    nx1 = szF(1);
    nx2 = szF(2);
    assert(nx1 == nx2, '2D F_seq must be square.');
    F_seq = reshape(F_seq, nx1, nx2, 1);
elseif numel(szF) == 3
    assert(szF(1) == szF(2), '3D F_seq must be [nx x nx x L].');
else
    error('F_seq must be [nx x nx] or [nx x nx x L].');
end

[nx, nx2, Lf] = size(F_seq); %#ok<ASGLU>
assert(nx == nx2, 'F_seq must be square in first two dimensions.');

[nx_x, Lx] = size(x_seq);
assert(nx_x == nx, 'x_seq first dimension must match F_seq size.');
assert(Lx == Lf, 'x_seq and F_seq must have the same horizon length.');

Rinv = inv(R);
W = zeros(nx, nx);

for ell = 1:Lf
    Fell = F_seq(:,:,ell);
    xell = x_seq(:,ell);
    Hell = H_fun(xell);

    assert(isnumeric(Hell) && ismatrix(Hell), 'H_fun must return a numeric matrix.');
    assert(size(Hell,2) == nx, 'H_fun output second dimension must match state dimension.');
    assert(size(Hell,1) == size(R,1), 'H_fun output first dimension must match R size.');

    W = W + Fell.' * Hell.' * Rinv * Hell * Fell;
end

W = 0.5 * (W + W.');
end
