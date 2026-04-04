function J = compute_bearing_fim_pair(r_tgt_eci_km, r_sat_pair_eci_km, sigma_angle_rad)
%COMPUTE_BEARING_FIM_PAIR
% Real bearing-only Fisher information for a double-satellite pair.
%
% Inputs:
%   r_tgt_eci_km      : 1x3 target position in ECI (km)
%   r_sat_pair_eci_km : 2x3 satellite positions in ECI (km)
%   sigma_angle_rad   : scalar angle std in rad
%
% Output:
%   J : 3x3 Fisher information on target position

assert(size(r_sat_pair_eci_km, 1) == 2 && size(r_sat_pair_eci_km, 2) == 3, ...
    'r_sat_pair_eci_km must be 2x3.');

sigma2 = sigma_angle_rad^2;
J = zeros(3,3);

for i = 1:2
    r_si = r_sat_pair_eci_km(i, :);
    rho = r_tgt_eci_km - r_si;
    range_km = norm(rho);
    assert(range_km > 0, 'Degenerate target-satellite range.');

    u = rho(:) / range_km;
    P_perp = eye(3) - (u * u.');

    % Bearing-only Fisher on Cartesian position:
    % J_i = (1/sigma^2) * (1/r^2) * (I - uu^T)
    J_i = (1 / sigma2) * (1 / (range_km^2)) * P_perp;
    J = J + J_i;
end

J = 0.5 * (J + J.');
end
