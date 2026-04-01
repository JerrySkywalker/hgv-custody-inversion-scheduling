function template_library = stage15_build_template_family_from_dataset(dataset)
%STAGE15_BUILD_TEMPLATE_FAMILY_FROM_DATASET
% Build a minimal conditioned template family from Stage15-B dataset.
%
% Current grouping key: risk_label only.

labels = string({dataset.risk_label});
u = unique(labels, 'stable');

template_library = struct( ...
    'template_id', {}, ...
    'risk_label', {}, ...
    'num_members', {}, ...
    'member_ids', {}, ...
    'xi_proto', {}, ...
    'kappa2_proto', {});

for i = 1:numel(u)
    label = u(i);
    mask = labels == label;
    group = dataset(mask);

    xi_r = mean(arrayfun(@(d) d.xi.r_norm, group));
    xi_b = mean(arrayfun(@(d) d.xi.bearing_rad, group));
    xi_h = mean(arrayfun(@(d) d.xi.heading_rad, group));
    xi_s = mean(arrayfun(@(d) d.xi.speed_norm, group));

    k_r1 = mean(arrayfun(@(d) d.kappa2.rho1_norm, group));
    k_r2 = mean(arrayfun(@(d) d.kappa2.rho2_norm, group));
    k_ang = mean(arrayfun(@(d) d.kappa2.crossing_angle_deg, group));
    k_lam = mean(arrayfun(@(d) d.kappa2.lambda_min_geom, group));

    tpl = struct();
    tpl.template_id = sprintf('TPL_%02d_%s', i, char(label));
    tpl.risk_label = char(label);
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
