function X_delay = build_delay_embedded_state(X, delay_order)
%BUILD_DELAY_EMBEDDED_STATE Build delay-embedded state matrix.
%
% Inputs:
%   X           : [nx x N]
%   delay_order : positive integer d
%
% Output:
%   X_delay     : [nx*d x (N-d+1)]

assert(isnumeric(X) && ismatrix(X), 'X must be a numeric matrix.');
assert(isnumeric(delay_order) && isscalar(delay_order) && delay_order >= 1, ...
    'delay_order must be a positive scalar.');

[nx, N] = size(X);
d = delay_order;
assert(N >= d, 'Not enough samples for requested delay_order.');

M = N - d + 1;
X_delay = zeros(nx * d, M);

for k = 1:M
    block = X(:, k:(k + d - 1));
    X_delay(:, k) = reshape(block, [], 1);
end
end
