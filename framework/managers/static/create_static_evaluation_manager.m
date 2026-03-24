function mgr = create_static_evaluation_manager(profile)
% Minimal bootstrap placeholder for the new framework.
if nargin < 1
    profile = struct();
end

mgr = struct();
mgr.profile = profile;
mgr.run = @() error('create_static_evaluation_manager:NotImplemented', ...
    'Static framework manager is not implemented yet.');
end
