function mgr = create_dynamic_scheduling_manager(profile)
if nargin < 1
    profile = struct();
end

mgr = struct();
mgr.profile = profile;
mgr.run = @() error('create_dynamic_scheduling_manager:NotImplemented', ...
    'Dynamic scheduling manager is not implemented yet.');
end
