function casebank = make_casebank_stage01(cfg)
    %MAKE_CASEBANK_STAGE01 Build complete Stage01 scenario casebank.
    
        disk = build_disk_region(cfg.stage01.disk_center_xy_km, cfg.stage01.R_D_km);
        entry = build_entry_boundary(cfg.stage01.disk_center_xy_km, ...
                                     cfg.stage01.R_in_km, ...
                                     cfg.stage01.num_nominal_entry_points);
    
        cases_nom  = generate_nominal_entry_family(disk, entry);
        cases_head = generate_heading_family(disk, entry, cfg.stage01.heading_offsets_deg);
        cases_crit = generate_critical_family(cfg);
    
        casebank = struct();
        casebank.disk = disk;
        casebank.entry = entry;
        casebank.nominal = cases_nom;
        casebank.heading = cases_head;
        casebank.critical = cases_crit;
        casebank.all_cases = [cases_nom; cases_head; cases_crit];
    
        casebank.summary = struct();
        casebank.summary.num_nominal = numel(cases_nom);
        casebank.summary.num_heading = numel(cases_head);
        casebank.summary.num_critical = numel(cases_crit);
        casebank.summary.num_total = numel(casebank.all_cases);
    end