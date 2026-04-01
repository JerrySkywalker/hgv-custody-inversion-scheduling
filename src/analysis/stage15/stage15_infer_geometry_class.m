function geometry_class = stage15_infer_geometry_class(xi)
%STAGE15_INFER_GEOMETRY_CLASS
% Minimal geometry class from local bearing.

b = stage15_wrap_to_pi_local(xi.bearing_rad);
ab = abs(b);

if ab <= pi/6
    geometry_class = 'front';
elseif ab <= pi/3
    geometry_class = 'oblique';
else
    geometry_class = 'grazing';
end
end

function a = stage15_wrap_to_pi_local(x)
a = mod(x + pi, 2*pi) - pi;
end
