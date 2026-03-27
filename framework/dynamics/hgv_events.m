function [value, isterminal, direction] = hgv_events(~, X, target_cfg, p)
%HGV_EVENTS Unified event function for target propagation.

v = X(1);
r = X(6);

h_m = r - p.Re;

value = [];
isterminal = [];
direction = [];

% Minimum altitude
value(end+1,1) = h_m - target_cfg.constraints.h_min_m;
isterminal(end+1,1) = 1;
direction(end+1,1) = -1;

% Maximum altitude
value(end+1,1) = target_cfg.constraints.h_max_m - h_m;
isterminal(end+1,1) = 1;
direction(end+1,1) = -1;

% Minimum speed
value(end+1,1) = v - target_cfg.constraints.v_min_mps;
isterminal(end+1,1) = 1;
direction(end+1,1) = -1;

% Maximum speed
value(end+1,1) = target_cfg.constraints.v_max_mps - v;
isterminal(end+1,1) = 1;
direction(end+1,1) = -1;

% Optional landing event
if target_cfg.constraints.enable_landing_event
    value(end+1,1) = h_m;
    isterminal(end+1,1) = 1;
    direction(end+1,1) = -1;
end
end
