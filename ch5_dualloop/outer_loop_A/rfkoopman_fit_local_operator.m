function A = rfkoopman_fit_local_operator(X)
%RFKOOPMAN_FIT_LOCAL_OPERATOR  Fit a local linear Koopman-style operator.
%
% Input:
%   X : [n x d] local lifted state sequence
%
% Output:
%   A : [d x d] local operator such that x_{k+1} ~= A * x_k

assert(size(X,1) >= 2, 'Need at least 2 samples to fit local operator.');

X0 = X(1:end-1, :);
X1 = X(2:end,   :);

A = X0 \ X1;
A = A.';
end
