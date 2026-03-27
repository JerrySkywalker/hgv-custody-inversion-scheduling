function track_specs = make_critical_track_specs(varargin)
%MAKE_CRITICAL_TRACK_SPECS Build explicit critical-track specs for chapter 4 experiments.

p = inputParser;
addParameter(p, 'entry_radius_km', 3000, @(x) isnumeric(x) && isscalar(x) && (x > 0));
addParameter(p, 'center_xy_km', [0, 0], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'scene_mode', "local_disk", @(x) ischar(x) || isstring(x));
addParameter(p, 'anchor_lat_deg', NaN, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'anchor_lon_deg', NaN, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'anchor_h_m', NaN, @(x) isnumeric(x) && isscalar(x));
parse(p, varargin{:});
opts = p.Results;

entry_radius_km = double(opts.entry_radius_km);
center_xy_km = double(opts.center_xy_km(:)).';

track_specs = struct([]);

track_specs(1).traj_id = "C1_track_plane_aligned";
track_specs(1).class_name = "critical";
track_specs(1).bundle_id = "critical_track_plane_aligned";
track_specs(1).entry_theta_deg = 0;
track_specs(1).heading_deg = 180;
track_specs(1).variation_kind = "critical_track_plane_aligned";
track_specs(1).entry_radius_km = entry_radius_km;
track_specs(1).center_xy_km = center_xy_km;
track_specs(1).generator_id = "explicit_track_set";
track_specs(1).scene_mode = char(string(opts.scene_mode));
track_specs(1).anchor_lat_deg = double(opts.anchor_lat_deg);
track_specs(1).anchor_lon_deg = double(opts.anchor_lon_deg);
track_specs(1).anchor_h_m = double(opts.anchor_h_m);

track_specs(2).traj_id = "C2_small_crossing_angle";
track_specs(2).class_name = "critical";
track_specs(2).bundle_id = "critical_small_crossing_angle";
track_specs(2).entry_theta_deg = 45;
track_specs(2).heading_deg = 200;
track_specs(2).variation_kind = "critical_small_crossing_angle";
track_specs(2).entry_radius_km = entry_radius_km;
track_specs(2).center_xy_km = center_xy_km;
track_specs(2).generator_id = "explicit_track_set";
track_specs(2).scene_mode = char(string(opts.scene_mode));
track_specs(2).anchor_lat_deg = double(opts.anchor_lat_deg);
track_specs(2).anchor_lon_deg = double(opts.anchor_lon_deg);
track_specs(2).anchor_h_m = double(opts.anchor_h_m);
end
