function r_ecef_m = geodetic_to_ecef(lat_deg, lon_deg, h_m, cfg_like)
%GEODETIC_TO_ECEF Convert geodetic coordinates to ECEF (spherical Earth fallback).
%
%   r_ecef_m = GEODETIC_TO_ECEF(lat_deg, lon_deg, h_m, cfg_like)

if nargin < 4
    error('geodetic_to_ecef:NotEnoughInputs', ...
        'lat_deg, lon_deg, h_m, and cfg_like are required.');
end

Re_m = resolve_earth_radius(cfg_like);

lat_rad = deg2rad(lat_deg);
lon_rad = deg2rad(lon_deg);

r = Re_m + h_m;

x = r .* cos(lat_rad) .* cos(lon_rad);
y = r .* cos(lat_rad) .* sin(lon_rad);
z = r .* sin(lat_rad);

r_ecef_m = [x(:), y(:), z(:)];
end

function Re_m = resolve_earth_radius(cfg_like)
if isstruct(cfg_like)
    if isfield(cfg_like, 'planet') && isstruct(cfg_like.planet) ...
            && isfield(cfg_like.planet, 're_m') && ~isempty(cfg_like.planet.re_m)
        Re_m = double(cfg_like.planet.re_m);
        return;
    end

    if isfield(cfg_like, 'geo') && isstruct(cfg_like.geo) ...
            && isfield(cfg_like.geo, 'a_m') && ~isempty(cfg_like.geo.a_m)
        Re_m = double(cfg_like.geo.a_m);
        return;
    end
end

Re_m = 6378137.0;
end
