function satbank = propagate_constellation(walker, t_s_common, engine_cfg)
%PROPAGATE_CONSTELLATION Propagate a Walker constellation on a shared time grid.
% Inputs:
%   walker     : walker struct from build_single_layer_walker()
%   t_s_common : common propagation time vector in seconds
%   engine_cfg : reserved for future engine-wide propagation options
%
% Output:
%   satbank    : propagated satellite state bank

if nargin < 3
    engine_cfg = []; %#ok<NASGU>
end

satbank = legacy_propagate_constellation_stage03_impl(walker, t_s_common);
end
