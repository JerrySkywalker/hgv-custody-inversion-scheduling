function template_library = stage15_build_conditioned_template_family_from_staticworld_dataset(dataset)
%STAGE15_BUILD_CONDITIONED_TEMPLATE_FAMILY_FROM_STATICWORLD_DATASET
% Build conditioned template family from F3 staticworld dataset.
%
% Group key:
%   geometry_class + layout_class + risk_label

keys = strings(1, numel(dataset));
for i = 1:numel(dataset)
    keys(i) = string(dataset(i).geometry_class) + "|" + ...
              string(dataset(i).layout_class) + "|" + ...
              string(dataset(i).risk_label);
end

u = unique(keys, 'stable');

template_library = struct( ...
    'template_id', {}, ...
    'geometry_class', {}, ...
    'layout_class', {}, ...
    'risk_label', {}, ...
    'num_members', {}, ...
    'member_ids', {}, ...
    'xi_proto', {}, ...
    'eta_proto', {}, ...
    'kappa2_proto', {});

for i = 1:numel(u)
    key = u(i);
    mask = keys == key;
    group = dataset(mask);

    gcls = group(1).geometry_class;
    lcls = group(1).layout_class;
    rlbl = group(1).risk_label;

    xi_rxy = mean(arrayfun(@(d) d.xi.r_norm_xy, group));
    xi_z   = mean(arrayfun(@(d) d.xi.z_norm, group));
    xi_b   = mean(arrayfun(@(d) d.xi.bearing_rad, group));
    xi_h   = mean(arrayfun(@(d) d.xi.heading_xy_rad, group));
    xi_s   = mean(arrayfun(@(d) d.xi.speed_norm, group));

    eta_rr = mean(arrayfun(@(d) d.eta.radial_rate_norm, group));
    eta_vr = mean(arrayfun(@(d) d.eta.vertical_rate_norm, group));
    eta_tp = mean(arrayfun(@(d) d.eta.turn_proxy, group));

    k_r1   = mean(arrayfun(@(d) d.kappa2.rho1_norm, group));
    k_r2   = mean(arrayfun(@(d) d.kappa2.rho2_norm, group));
    k_h1   = mean(arrayfun(@(d) d.kappa2.delta_h1_norm, group));
    k_h2   = mean(arrayfun(@(d) d.kappa2.delta_h2_norm, group));
    k_ang  = mean(arrayfun(@(d) d.kappa2.crossing_angle_deg, group));
    k_lam  = mean(arrayfun(@(d) d.kappa2.lambda_min_geom, group));

    tpl = struct();
    tpl.template_id = sprintf('SWTPL_%02d_%s_%s_%s', i, gcls, lcls, rlbl);
    tpl.geometry_class = gcls;
    tpl.layout_class = lcls;
    tpl.risk_label = rlbl;
    tpl.num_members = numel(group);
    tpl.member_ids = {group.sample_id};

    tpl.xi_proto = struct( ...
        'r_norm_xy', xi_rxy, ...
        'z_norm', xi_z, ...
        'bearing_rad', xi_b, ...
        'heading_xy_rad', xi_h, ...
        'speed_norm', xi_s);

    tpl.eta_proto = struct( ...
        'radial_rate_norm', eta_rr, ...
        'vertical_rate_norm', eta_vr, ...
        'turn_proxy', eta_tp);

    tpl.kappa2_proto = struct( ...
        'rho1_norm', k_r1, ...
        'rho2_norm', k_r2, ...
        'delta_h1_norm', k_h1, ...
        'delta_h2_norm', k_h2, ...
        'crossing_angle_deg', k_ang, ...
        'lambda_min_geom', k_lam);

    template_library(end+1) = tpl; %#ok<AGROW>
end
end
