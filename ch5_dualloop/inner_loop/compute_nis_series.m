function nis = compute_nis_series(innovations, S_series)
%COMPUTE_NIS_SERIES  Compute scalar NIS time series.
%
% innovations : [N x m]
% S_series     : [m x m x N]

N = size(innovations, 1);
nis = zeros(N, 1);

for k = 1:N
    v = innovations(k, :).';
    S = S_series(:, :, k);

    % Numerical guard.
    S = 0.5 * (S + S.');
    if rcond(S) < 1e-12
        S = S + 1e-9 * eye(size(S));
    end

    nis(k) = v' * (S \ v);
end
end
