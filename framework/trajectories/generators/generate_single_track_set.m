function items = generate_single_track_set(track_specs, varargin)
%GENERATE_SINGLE_TRACK_SET Generate tracks from explicit track definitions.
%
%   items = GENERATE_SINGLE_TRACK_SET(track_specs)
%
%   track_specs must be a non-empty struct array. Required fields per spec:
%     - traj_id
%     - class_name
%     - bundle_id
%     - entry_theta_deg
%     - heading_deg
%
%   Optional fields:
%     - generator_id
%     - source_kind
%     - base_traj_id
%     - sample_id
%     - variation_kind
%     - entry_radius_km
%     - center_xy_km
%     - heading_offset_deg
%     - scene_mode
%     - anchor_lat_deg
%     - anchor_lon_deg
%     - anchor_h_m

p = inputParser;
addRequired(p, 'track_specs', @(x) isstruct(x) && ~isempty(x));
parse(p, track_specs);

n = numel(track_specs);

traj_id = strings(n,1);
class_name = strings(n,1);
bundle_id = strings(n,1);
source_kind = strings(n,1);
generator_id = strings(n,1);
base_traj_id = strings(n,1);
sample_id = zeros(n,1);
variation_kind = strings(n,1);
payload = cell(n,1);

for k = 1:n
    spec = track_specs(k);

    must_have_field(spec, 'traj_id');
    must_have_field(spec, 'class_name');
    must_have_field(spec, 'bundle_id');
    must_have_field(spec, 'entry_theta_deg');
    must_have_field(spec, 'heading_deg');

    this_traj_id = string(spec.traj_id);
    this_class_name = string(spec.class_name);
    this_bundle_id = string(spec.bundle_id);

    this_source_kind = get_or_default(spec, 'source_kind', "generator");
    this_generator_id = get_or_default(spec, 'generator_id', "single_track_set");
    this_base_traj_id = get_or_default(spec, 'base_traj_id', "");
    this_sample_id = get_or_default(spec, 'sample_id', 1);
    this_variation_kind = get_or_default(spec, 'variation_kind', "");

    entry_theta_deg = double(spec.entry_theta_deg);
    heading_deg = double(spec.heading_deg);
    heading_offset_deg = double(get_or_default(spec, 'heading_offset_deg', 0));

    center_xy_km = double(get_or_default(spec, 'center_xy_km', [0, 0]));
    center_xy_km = center_xy_km(:).';
    entry_radius_km = get_or_default(spec, 'entry_radius_km', []);
    if isempty(entry_radius_km)
        entry_radius_km = NaN;
    else
        entry_radius_km = double(entry_radius_km);
    end

    scene_mode = char(string(get_or_default(spec, 'scene_mode', "local_disk")));
    anchor_lat_deg = double(get_or_default(spec, 'anchor_lat_deg', NaN));
    anchor_lon_deg = double(get_or_default(spec, 'anchor_lon_deg', NaN));
    anchor_h_m = double(get_or_default(spec, 'anchor_h_m', NaN));

    if ~isnan(entry_radius_km)
        entry_point_xy_km = center_xy_km + entry_radius_km * [cosd(entry_theta_deg), sind(entry_theta_deg)];
    else
        entry_point_xy_km = [NaN, NaN];
    end

    heading_unit_xy = [cosd(heading_deg), sind(heading_deg)];

    traj_id(k) = this_traj_id;
    class_name(k) = this_class_name;
    bundle_id(k) = this_bundle_id;
    source_kind(k) = string(this_source_kind);
    generator_id(k) = string(this_generator_id);
    base_traj_id(k) = string(this_base_traj_id);
    sample_id(k) = double(this_sample_id);
    variation_kind(k) = string(this_variation_kind);

    payload{k} = struct( ...
        'entry_theta_deg', entry_theta_deg, ...
        'heading_deg', heading_deg, ...
        'heading_offset_deg', heading_offset_deg, ...
        'entry_point_xy_km', entry_point_xy_km, ...
        'heading_unit_xy', heading_unit_xy, ...
        'entry_point_enu_km', entry_point_xy_km, ...
        'entry_point_enu_m', entry_point_xy_km * 1000, ...
        'heading_unit_enu', heading_unit_xy, ...
        'center_xy_km', center_xy_km, ...
        'entry_radius_km', entry_radius_km, ...
        'scene_mode', scene_mode, ...
        'anchor_lat_deg', anchor_lat_deg, ...
        'anchor_lon_deg', anchor_lon_deg, ...
        'anchor_h_m', anchor_h_m);
end

items = make_trajectory_item_table( ...
    traj_id, class_name, bundle_id, source_kind, generator_id, ...
    base_traj_id, sample_id, variation_kind, payload);
end

function must_have_field(s, field_name)
if ~isfield(s, field_name)
    error('generate_single_track_set:MissingField', ...
        'track_specs is missing required field: %s', field_name);
end
end

function value = get_or_default(s, field_name, default_value)
if isfield(s, field_name) && ~isempty(s.(field_name))
    value = s.(field_name);
else
    value = default_value;
end
end
