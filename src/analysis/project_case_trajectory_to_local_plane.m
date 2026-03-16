function xy_km = project_case_trajectory_to_local_plane(ecef_traj_m, zone)
%PROJECT_CASE_TRAJECTORY_TO_LOCAL_PLANE Project ECEF trajectory to local EN plane.

rel_m = ecef_traj_m - zone.center_ecef_m(:).';
east_m = rel_m * zone.east_hat(:);
north_m = rel_m * zone.north_hat(:);
xy_km = [east_m, north_m] / 1000;
end
