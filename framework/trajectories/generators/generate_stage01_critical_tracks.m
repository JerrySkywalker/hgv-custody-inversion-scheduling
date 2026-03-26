function items = generate_stage01_critical_tracks(varargin)
%GENERATE_STAGE01_CRITICAL_TRACKS Generate default critical tracks for Stage01.
%
%   items = GENERATE_STAGE01_CRITICAL_TRACKS()
%   items = GENERATE_STAGE01_CRITICAL_TRACKS('entry_radius_km', 3000, ...)
%
%   This is a Stage01-specific adapter built on top of
%   generate_single_track_set.

p = inputParser;
addParameter(p, 'entry_radius_km', 3000, @(x) isnumeric(x) && isscalar(x) && (x > 0));
addParameter(p, 'center_xy_km', [0, 0], @(x) isnumeric(x) && numel(x) == 2);
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
track_specs(1).generator_id = "stage01_critical_tracks";

track_specs(2).traj_id = "C2_small_crossing_angle";
track_specs(2).class_name = "critical";
track_specs(2).bundle_id = "critical_small_crossing_angle";
track_specs(2).entry_theta_deg = 45;
track_specs(2).heading_deg = 200;
track_specs(2).variation_kind = "critical_small_crossing_angle";
track_specs(2).entry_radius_km = entry_radius_km;
track_specs(2).center_xy_km = center_xy_km;
track_specs(2).generator_id = "stage01_critical_tracks";

items = generate_single_track_set(track_specs);
end
