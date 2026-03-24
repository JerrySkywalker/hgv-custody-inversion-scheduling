function [risk_table, detail_bank] = scan_heading_risk_map_stage07(base_case_item, reference_walker, scope_spec, cfg, disable_detail_bank)
    %SCAN_HEADING_RISK_MAP_STAGE07
    % Stage07.3 core scanner:
    %   For one nominal entry case, scan heading offsets under fixed reference Walker.
    %
    % Input:
    %   base_case_item     : one nominal case item from Stage02 trajbank.nominal
    %   reference_walker   : out7_1.reference_walker
    %   scope_spec         : out7_2.spec
    %   cfg                : default params
    %
    % Output:
    %   risk_table         : one-row-per-heading evaluation table
    %   detail_bank        : cell array of detailed outputs per heading
    %
    % Notes:
    %   - This function rebuilds the target trajectory for each heading offset
    %   - Then it evaluates geometry using the fixed reference Walker
    %   - It relies on Stage02 propagation + Stage03 visibility + Stage04 window scan
    
    if nargin < 4 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 5
        disable_detail_bank = false;
    end
    
        assert(isstruct(base_case_item) && isfield(base_case_item, 'case'), ...
            'base_case_item must be one Stage02 nominal traj item with .case');
        assert(isstruct(reference_walker), 'reference_walker must be struct');
        assert(isstruct(scope_spec), 'scope_spec must be struct');
    
        base_case = base_case_item.case;
        heading_offsets_deg = scope_spec.heading_scan.offset_grid_deg(:);
        nHead = numel(heading_offsets_deg);
    
        detail_bank = cell(nHead, 1);
        row_bank = cell(nHead, 1);
    
        nominal_heading_deg = local_extract_numeric(base_case, 'heading_deg', NaN);
        assert(isfinite(nominal_heading_deg), 'Base nominal case missing heading_deg.');
    
        entry_id = local_extract_numeric(base_case, 'entry_id', NaN);
        if ~isfinite(entry_id)
            entry_id = local_parse_entry_id_from_case_id(base_case);
        end
    
        entry_lat_deg = local_extract_numeric(base_case, 'entry_lat_deg', NaN);
        entry_lon_deg = local_extract_numeric(base_case, 'entry_lon_deg', NaN);
    
        for k = 1:nHead
            heading_offset_deg = heading_offsets_deg(k);
            heading_deg = wrapTo360(nominal_heading_deg + heading_offset_deg);
    
            % --------------------------------------------------------
            % rebuild case with this heading
            % --------------------------------------------------------
            case_k = base_case;
            case_k.heading_deg = heading_deg;
            case_k.heading_offset_deg = heading_offset_deg;
            case_k.nominal_heading_deg = nominal_heading_deg;
            case_k.entry_id = entry_id;
            case_k.entry_point_id = entry_id;
            case_k.family = 'critical_heading_scan';
            case_k.subfamily = 'heading_scan';
            case_k.source_case_id = char(string(base_case.case_id));
            case_k.case_id = sprintf('SCAN_E%02d_H%+04d', entry_id, round(heading_offset_deg));
    
            % --------------------------------------------------------
            % re-propagate target under new heading
            % --------------------------------------------------------
            traj_k = propagate_hgv_case_stage02(case_k, cfg);
            val_k = validate_hgv_trajectory_stage02(traj_k, cfg);
            sum_k = summarize_hgv_case_stage02(case_k, traj_k, val_k);
    
            case_item_k = struct();
            case_item_k.case = case_k;
            case_item_k.traj = traj_k;
            case_item_k.validation = val_k;
            case_item_k.summary = sum_k;
    
            % --------------------------------------------------------
            % evaluate under fixed reference walker
            % --------------------------------------------------------
            eval_k = evaluate_critical_case_geometry_stage07(case_item_k, reference_walker, scope_spec.gamma_req, cfg);
    
            row = eval_k.diag_row;
            row.source_nominal_case_id = string(base_case.case_id);
            row.entry_id = entry_id;
            row.entry_lat_deg = entry_lat_deg;
            row.entry_lon_deg = entry_lon_deg;
            row.nominal_heading_deg = nominal_heading_deg;
            row.heading_offset_deg = heading_offset_deg;
            row.heading_deg = heading_deg;
    
            % C1 local reference heading(s)
            [c1_heading_asc_deg, c1_heading_desc_deg] = local_estimate_trackplane_headings(entry_lat_deg, reference_walker.i_deg);
            row.C1_heading_asc_deg = c1_heading_asc_deg;
            row.C1_heading_desc_deg = c1_heading_desc_deg;
            row.C1_offset_asc_deg = wrapTo180(c1_heading_asc_deg - heading_deg);
            row.C1_offset_desc_deg = wrapTo180(c1_heading_desc_deg - heading_deg);
            row.C1_distance_to_nearest_deg = min(abs([row.C1_offset_asc_deg, row.C1_offset_desc_deg]));
    
            % danger flags under Stage07 thresholds
            row.is_high_coverage = row.coverage_ratio_2sat >= scope_spec.danger.coverage_good_threshold;
            row.is_small_angle = row.mean_los_intersection_angle_deg <= scope_spec.danger.angle_bad_threshold_deg;
            row.is_low_DG = row.D_G_min < scope_spec.danger.D_G_bad_threshold;
            row.is_low_lambda = row.lambda_worst < scope_spec.danger.lambda_bad_factor * scope_spec.gamma_req;
    
            row.is_counterexample_candidate = row.is_high_coverage && ...
                (row.is_small_angle || row.is_low_DG || row.is_low_lambda);
    
            row_bank{k} = row;
        if disable_detail_bank
            detail_bank{k} = [];
        else
            detail_bank{k} = eval_k;
        end
        end
    
        risk_table = struct2table(vertcat(row_bank{:}));
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    function x = local_extract_numeric(S, field_name, fallback)
        x = fallback;
        if isstruct(S) && isfield(S, field_name)
            val = S.(field_name);
            if isnumeric(val) && ~isempty(val) && isfinite(val(1))
                x = double(val(1));
            end
        end
    end
    
    
    function entry_id = local_parse_entry_id_from_case_id(base_case)
        entry_id = NaN;
        if isfield(base_case, 'case_id') && ~isempty(base_case.case_id)
            cid = char(string(base_case.case_id));
            tok = regexp(cid, '^N(\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                entry_id = str2double(tok{1});
            end
        end
    end
    
    
    function [h_asc_deg, h_desc_deg] = local_estimate_trackplane_headings(lat_deg, inc_deg)
        ratio = cosd(inc_deg) / max(cosd(lat_deg), eps);
        ratio = min(max(ratio, -1), 1);
    
        alpha = acosd(ratio);
        h_asc_deg = wrapTo360(alpha);
        h_desc_deg = wrapTo360(180 - alpha);
    end
