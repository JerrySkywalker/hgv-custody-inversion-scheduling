function Cr = build_requirement_projection_Cr(nx, mode)
%BUILD_REQUIREMENT_PROJECTION_CR Build critical-subspace projection matrix C_r.
%
% Inputs:
%   nx   : state dimension
%   mode : 'position' or 'full'
%
% Output:
%   Cr   : projection matrix
%
% Current minimal support:
%   nx = 6:
%     'position' -> select first 3 states
%     'full'     -> identity

assert(isnumeric(nx) && isscalar(nx) && nx >= 1, 'nx must be a positive scalar.');
assert(ischar(mode) || isstring(mode), 'mode must be a char or string.');
mode = char(string(mode));

switch lower(mode)
    case 'position'
        assert(nx >= 3, 'position mode requires nx >= 3.');
        Cr = [eye(3), zeros(3, nx - 3)];
    case 'full'
        Cr = eye(nx);
    otherwise
        error('Unsupported C_r mode: %s', mode);
end
end
