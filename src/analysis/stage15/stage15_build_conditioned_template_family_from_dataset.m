function template_library = stage15_build_conditioned_template_family_from_dataset(dataset)
%STAGE15_BUILD_CONDITIONED_TEMPLATE_FAMILY_FROM_DATASET
% Build conditioned template family from dataset.
%
% Group key:
%   geometry_class + heading_class + risk_label

for i = 1:numel(dataset)
    dataset(i).geometry_class = stage15_infer_geometry_class(dataset(i).xi); %#ok<AGROW>
    dataset(i).heading_class = stage15_infer_heading_class(dataset(i).xi); %#ok<AGROW>
end

keys = strings(1, numel(dataset));
for i = 1:numel(dataset)
    keys(i) = string(dataset(i).geometry_class) + "|" + ...
              string(dataset(i).heading_class) + "|" + ...
              string(dataset(i).risk_label);
end

u = unique(keys, 'stable');

template_library = struct( ...
    'template_id', {}, ...
    'geometry_class', {}, ...
    'heading_class', {}, ...
    'risk_label', {}, ...
    'num_members', {}, ...
    'member_ids', {}, ...
    'xi_proto', {}, ...
    'kappa2_proto', {});

for i = 1:numel(u)
    key = u(i);
    mask = keys == key;
    group = dataset(mask);

    gcls = group(1).geometry_class;
    hcls = group(1).heading_class;
    rlbl = group(1).risk_label;

    xi_r = mean(arrayfun(@(d) d.xi.r_norm, group));
    xi_b = mean(arrayfun(@(d) d.xi.bearing_rad, group));
    xi_h = mean(arrayfun(@(d) d.xi.heading_rad, group));
    xi_s = mean(arrayfun(@(d) d.xi.speed_norm, group));

    k_r1 = mean(arrayfun(@(d) d.kappa2.rho1_norm, group));
    k_r2 = mean(arrayfun(@(d) d.kappa2.rho2_norm, group));
    k_ang = mean(arrayfun(@(d) d.kappa2.crossing_angle_deg, group));
    k_lam = mean(arrayfun(@(d) d.kappa2.lambda_min_geom, group));

    tpl = struct();
    tpl.template_id = sprintf('CTPL_%02d_%s_%s_%s', i, gcls, hcls, rlbl);
    tpl.geometry_class = gcls;
    tpl.heading_class = hcls;
    tpl.risk_label = rlbl;
    tpl.num_members = numel(group);
    tpl.member_ids = {group.sample_id};

    tpl.xi_proto = struct( ...
        'r_norm', xi_r, ...
        'bearing_rad', xi_b, ...
        'heading_rad', xi_h, ...
        'speed_norm', xi_s);

    tpl.kappa2_proto = struct( ...
        'rho1_norm', k_r1, ...
        'rho2_norm', k_r2, ...
        'crossing_angle_deg', k_ang, ...
        'lambda_min_geom', k_lam);

    template_library(end+1) = tpl; %#ok<AGROW>
end
end
