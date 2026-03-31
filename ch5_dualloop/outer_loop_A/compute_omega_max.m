function omega_max = compute_omega_max(mr_hat)
%COMPUTE_OMEGA_MAX  Compute bounded maximum positive risk growth rate.
%
% Use a bounded transform z = mr / (1 + mr) before taking positive diff.

if numel(mr_hat) <= 1
    omega_max = 0;
    return;
end

x = mr_hat(:);
x = max(0, x);

z = x ./ (1 + x);
d = diff(z);

omega_max = max([0; d]);
end
