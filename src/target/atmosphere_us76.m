function [rho, a_s] = atmosphere_us76(h_m)
%atmosphere_us76 Minimal US76-like atmosphere.
% If you want exact match to Chapter2, replace body with your original atmosphere_US76_manual.m.

% Simple piecewise exponential density + constant speed of sound placeholder
% (KEEP THIS ONLY AS FALLBACK; prefer copying your exact Chapter2 function.)
h = max(h_m,0);

% crude density model
rho0 = 1.225; H = 7200;     % scale height
rho = rho0 * exp(-h/H);

% crude speed of sound
a_s = 295; % m/s (placeholder)
end