function family_out = stage06_build_heading_family(trajs_nominal, heading_offsets_deg, varargin)
    %STAGE06_BUILD_HEADING_FAMILY
    % Build Stage06 heading-extended family from Stage02 nominal trajectory bank.
    %
    % Usage:
    %   family_out = stage06_build_heading_family(trajs_nominal, heading_offsets_deg)
    %   family_out = stage06_build_heading_family(..., 'HeadingMode', 'small')
    %   family_out = stage06_build_heading_family(..., 'FamilyType', 'heading_extended')
    %
    % Input:
    %   trajs_nominal        : Stage02 nominal trajbank struct array
    %   heading_offsets_deg  : vector, e.g. [0 -30 30]
    %
    % Output:
    %   family_out           : struct array, same outer format as Stage02 trajbank items
    %                          with enriched case/meta labels for Stage06
    %
    % Notes:
    %   - This version does NOT re-integrate dynamics.
    %   - Entry-point set remains unchanged.
    %   - Each nominal case is replicated across heading offsets.
    %   - The generated family is intended for Stage06 search-chain integration.
    
        arguments
            trajs_nominal struct
            heading_offsets_deg double
        end
    
        arguments (Repeating)
            varargin
        end
    
        heading_offsets_deg = heading_offsets_deg(:).';
    
        p = inputParser;
        addParameter(p, 'HeadingMode', 'small');
        addParameter(p, 'FamilyType', 'heading_extended');
        parse(p, varargin{:});
    
        heading_mode = string(p.Results.HeadingMode);
        family_type = string(p.Results.FamilyType);
    
        n_nominal = numel(trajs_nominal);
        n_heading = numel(heading_offsets_deg);
        n_total = n_nominal * n_heading;
    
        if n_nominal == 0
            family_out = struct('case', {}, 'traj', {}, 'validation', {}, 'summary', {});
            return;
        end
    
        family_out = repmat(local_empty_item(), n_total, 1);
    
        idx = 0;
        for iCase = 1:n_nominal
            base_item = trajs_nominal(iCase);
    
            for j = 1:n_heading
                idx = idx + 1;
                offset_deg = heading_offsets_deg(j);
    
                new_item = local_apply_heading_offset_to_case( ...
                    base_item, iCase, offset_deg, heading_mode, family_type);
    
                family_out(idx) = new_item;
            end
        end
    end
    
    % =========================================================================
    % Local: apply heading offset label / metadata to one nominal trajectory item
    % =========================================================================
    function out_item = local_apply_heading_offset_to_case(base_item, entry_id, offset_deg, heading_mode, family_type)
    
        out_item = base_item;
    
        % ---------------------------------------------------------------------
        % source identifiers
        % ---------------------------------------------------------------------
        if isfield(base_item, 'case') && isfield(base_item.case, 'case_id')
            source_case_id = string(base_item.case.case_id);
        else
            source_case_id = "unknown_case";
        end
    
        % nominal heading
        nominal_heading_deg = NaN;
        if isfield(base_item, 'case') && isfield(base_item.case, 'heading_deg')
            nominal_heading_deg = base_item.case.heading_deg;
        elseif isfield(base_item, 'traj') && isfield(base_item.traj, 'meta') && ...
               isfield(base_item.traj.meta, 'heading_deg')
            nominal_heading_deg = base_item.traj.meta.heading_deg;
        end
    
        perturbed_heading_deg = nominal_heading_deg + offset_deg;
    
        heading_label = local_heading_label(offset_deg);
        new_case_id = sprintf('E%02d_%s', entry_id, char(heading_label));
    
        % ---------------------------------------------------------------------
        % patch case
        % ---------------------------------------------------------------------
        if ~isfield(out_item, 'case') || isempty(out_item.case)
            out_item.case = struct();
        end
    
        out_item.case.case_id = new_case_id;
        out_item.case.family = char(family_type);
        out_item.case.subfamily = sprintf('stage06_%s', char(heading_mode));
        out_item.case.entry_id = entry_id;
        out_item.case.entry_point_id = entry_id;
        out_item.case.source_case_id = char(source_case_id);
        out_item.case.family_origin = 'stage02_nominal';
        out_item.case.heading_mode = char(heading_mode);
        out_item.case.heading_label = char(heading_label);
    
        % preserve nominal heading as reference
        out_item.case.nominal_heading_deg = nominal_heading_deg;
        out_item.case.heading_offset_deg = offset_deg;
        out_item.case.heading_deg = perturbed_heading_deg;
    
        if ~isfield(out_item.case, 'notes') || isempty(out_item.case.notes)
            out_item.case.notes = '';
        end
        out_item.case.notes = sprintf([ ...
            'Stage06 heading-extended family item. ', ...
            'Replicated from nominal case %s with heading offset %+g deg.'], ...
            char(source_case_id), offset_deg);
    
        % ---------------------------------------------------------------------
        % patch traj top-level tags
        % ---------------------------------------------------------------------
        if ~isfield(out_item, 'traj') || isempty(out_item.traj)
            out_item.traj = struct();
        end
    
        if isfield(out_item.traj, 'case_id')
            out_item.traj.case_id = new_case_id;
        end
        if isfield(out_item.traj, 'family')
            out_item.traj.family = char(family_type);
        end
        if isfield(out_item.traj, 'subfamily')
            out_item.traj.subfamily = sprintf('stage06_%s', char(heading_mode));
        end
    
        % ---------------------------------------------------------------------
        % patch traj.meta
        % ---------------------------------------------------------------------
        if ~isfield(out_item.traj, 'meta') || isempty(out_item.traj.meta)
            out_item.traj.meta = struct();
        end
    
        out_item.traj.meta.entry_id = entry_id;
        out_item.traj.meta.entry_point_id = entry_id;
        out_item.traj.meta.source_case_id = char(source_case_id);
        out_item.traj.meta.family_origin = 'stage02_nominal';
        out_item.traj.meta.heading_mode = char(heading_mode);
        out_item.traj.meta.heading_label = char(heading_label);
        out_item.traj.meta.nominal_heading_deg = nominal_heading_deg;
        out_item.traj.meta.heading_offset_deg = offset_deg;
        out_item.traj.meta.heading_deg = perturbed_heading_deg;
        out_item.traj.meta.is_heading_extended_copy = true;
    
        % ---------------------------------------------------------------------
        % patch summary if present
        % ---------------------------------------------------------------------
        if isfield(out_item, 'summary') && ~isempty(out_item.summary)
            if isfield(out_item.summary, 'case_id')
                out_item.summary.case_id = new_case_id;
            end
            if isfield(out_item.summary, 'family')
                out_item.summary.family = char(family_type);
            end
            out_item.summary.entry_id = entry_id;
            out_item.summary.heading_offset_deg = offset_deg;
            out_item.summary.heading_label = char(heading_label);
            out_item.summary.source_case_id = char(source_case_id);
        end
    end
    
    % =========================================================================
    % Local: heading label
    % =========================================================================
    function label = local_heading_label(offset_deg)
        if abs(offset_deg) < 1e-12
            label = "h0";
        elseif offset_deg > 0
            label = sprintf('hp%02d', round(abs(offset_deg)));
        else
            label = sprintf('hm%02d', round(abs(offset_deg)));
        end
    end
    
    % =========================================================================
    % Local: empty output item
    % =========================================================================
    function s = local_empty_item()
        s = struct( ...
            'case', [], ...
            'traj', [], ...
            'validation', [], ...
            'summary', []);
    end