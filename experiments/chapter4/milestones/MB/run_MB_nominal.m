function run_MB_nominal()
profile = make_profile_MB_nominal();
mgr = create_static_evaluation_manager(profile);
mgr.run();
end
