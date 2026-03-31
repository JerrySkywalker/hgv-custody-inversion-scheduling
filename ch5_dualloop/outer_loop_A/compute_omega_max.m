function omega_max = compute_omega_max(mr_hat)
%COMPUTE_OMEGA_MAX  Compute maximum positive risk growth rate over a horizon.

if numel(mr_hat) <= 1
    omega_max = 0;
    return;
end

d = diff(mr_hat(:));
omega_max = max([0; d]);
end
