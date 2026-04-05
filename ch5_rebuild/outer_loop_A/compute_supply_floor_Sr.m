function out = compute_supply_floor_Sr(MG_forecast_series)
%COMPUTE_SUPPLY_FLOOR_SR Compute future-window weakest supply floor.
%
% Inputs:
%   MG_forecast_series : [H x 1] structure metric forecast series
%
% Outputs:
%   out.S_r            : weakest supply floor over the window
%   out.idx_min        : index of weakest future step
%   out.MG_forecast    : copied input vector
%
% Definition:
%   S_r = min_{ell=0,...,H-1} M_G(k+ell|k)

MG_forecast_series = MG_forecast_series(:);

assert(isnumeric(MG_forecast_series) && isvector(MG_forecast_series) && ~isempty(MG_forecast_series), ...
    'MG_forecast_series must be a non-empty numeric vector.');

[S_r, idx_min] = min(MG_forecast_series);

out = struct();
out.S_r = S_r;
out.idx_min = idx_min;
out.MG_forecast = MG_forecast_series;
end
