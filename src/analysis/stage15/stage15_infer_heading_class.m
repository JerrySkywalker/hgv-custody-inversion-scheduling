function heading_class = stage15_infer_heading_class(xi)
%STAGE15_INFER_HEADING_CLASS
% Minimal heading class from heading relative to bearing.

d = stage15_wrap_to_pi_local(xi.heading_rad - xi.bearing_rad);

c = abs(cos(d));
s = abs(sin(d));

if c >= 0.85
    heading_class = 'radial';
elseif s >= 0.85
    heading_class = 'tangential';
else
    heading_class = 'oblique';
end
end

function a = stage15_wrap_to_pi_local(x)
a = mod(x + pi, 2*pi) - pi;
end
