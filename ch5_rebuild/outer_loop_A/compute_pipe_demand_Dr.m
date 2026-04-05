function out = compute_pipe_demand_Dr(MR_forecast_series, dt, rho_r)
%COMPUTE_PIPE_DEMAND_DR Map trajectory-pipe expansion to weakest-direction demand.
%
% Inputs:
%   MR_forecast_series : [H x 1] forecast demand-expansion rate series
%   dt                 : time step
%   rho_r              : conservative weakest-direction mapping coefficient
%
% Outputs:
%   out.D_r            : cumulative weakest-direction demand
%   out.MR_positive    : positive-part MR series
%   out.sum_positive   : sum of positive-part MR series
%
% Definition:
%   D_r = rho_r * sum_{ell=0}^{H-1} max(0, MR(k+ell|k)) * dt

MR_forecast_series = MR_forecast_series(:);

assert(isnumeric(MR_forecast_series) && isvector(MR_forecast_series), ...
    'MR_forecast_series must be a numeric vector.');
assert(isnumeric(dt) && isscalar(dt) && dt > 0, 'dt must be positive.');
assert(isnumeric(rho_r) && isscalar(rho_r) && rho_r > 0, 'rho_r must be positive.');

MR_positive = max(MR_forecast_series, 0);
sum_positive = sum(MR_positive);

out = struct();
out.D_r = rho_r * sum_positive * dt;
out.MR_positive = MR_positive;
out.sum_positive = sum_positive;
end
