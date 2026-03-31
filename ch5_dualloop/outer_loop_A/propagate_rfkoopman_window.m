function Xpred = propagate_rfkoopman_window(x0, A, H)
%PROPAGATE_RFKOOPMAN_WINDOW  Propagate local linear Koopman-style model.
%
% Input:
%   x0 : [d x 1]
%   A  : [d x d]
%   H  : horizon steps
%
% Output:
%   Xpred : [H x d]

d = numel(x0);
Xpred = zeros(H, d);

x = x0(:);
for k = 1:H
    x = A * x;
    Xpred(k, :) = x(:).';
end
end
