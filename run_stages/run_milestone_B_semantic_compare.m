function out = run_milestone_B_semantic_compare(cfg, interactive)
%RUN_MILESTONE_B_SEMANTIC_COMPARE CLI entry for MB semantic comparison.
%
% Usage:
%   out = run_milestone_B_semantic_compare()
%   out = run_milestone_B_semantic_compare(cfg, false)
%
% Interactive mode supports:
%   - mode: legacyDG / closedD / comparison / all
%   - sensor groups: baseline / optimistic / robust / all / comma list
%   - baseline validation shortcut (default yes, uses h = 1000 km)
%   - heights: validation / default / custom
%   - family set: nominal / heading / critical / all / comma list
%   - dense local refinement, fast mode, resume checkpoint

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = milestone_common_defaults();
    else
        cfg = milestone_common_defaults(cfg);
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end

    [cfg, selection] = mb_cli_configure_search_profile(cfg, interactive);
    if interactive
        cfg = local_configure_runtime(cfg, selection);
    end

    fprintf('[run_stages] === MB semantic compare ===\n');
    fprintf('[run_stages] profile=%s | mode=%s | sensor_groups=%s | heights=%s | families=%s | dense_local=%s | fast_mode=%s\n', ...
        char(string(cfg.milestones.MB_semantic_compare.search_profile)), ...
        char(string(cfg.milestones.MB_semantic_compare.mode)), ...
        strjoin(resolve_sensor_param_groups(cfg.milestones.MB_semantic_compare.sensor_groups), ','), ...
        mat2str(cfg.milestones.MB_semantic_compare.heights_to_run), ...
        strjoin(cellstr(string(cfg.milestones.MB_semantic_compare.family_set)), ','), ...
        char(string(logical(cfg.milestones.MB_semantic_compare.run_dense_local))), ...
        char(string(logical(cfg.milestones.MB_semantic_compare.fast_mode))));

    out = milestone_B_semantic_compare(cfg);
    fprintf('[run_stages] MB semantic compare complete: status=%s\n', char(string(out.summary.execution_status)));
end

function cfg = local_configure_runtime(cfg, selection)
    meta = cfg.milestones.MB_semantic_compare;
    fprintf('[run_stages][CLI] 当前 search profile: %s\n', char(string(selection.profile_name)));
    family_token = local_ask_csv_token('family set', strjoin(cellstr(string(meta.family_set)), ','), {'nominal', 'heading', 'critical', 'all'});
    run_dense_local = local_ask_yesno('run dense local refinement', logical(meta.run_dense_local));
    fast_mode = local_ask_yesno('fast mode', logical(meta.fast_mode));
    resume_checkpoint = local_ask_yesno('resume checkpoint', logical(meta.resume_checkpoint));

    cfg.milestones.MB_semantic_compare.family_set = local_parse_csv_cell(family_token);
    cfg.milestones.MB_semantic_compare.run_dense_local = run_dense_local;
    cfg.milestones.MB_semantic_compare.fast_mode = fast_mode;
    cfg.milestones.MB_semantic_compare.resume_checkpoint = resume_checkpoint;
end

function token = local_ask_csv_token(name, default_val, allowed_values)
    prompt = sprintf('%s [%s] options=%s: ', name, default_val, strjoin(allowed_values, '/'));
    s = input(prompt, 's');
    if isempty(strtrim(s))
        token = default_val;
        return;
    end
    parts = local_parse_csv_cell(s);
    if any(strcmpi(parts, 'all'))
        token = 'all';
        return;
    end
    for idx = 1:numel(parts)
        if ~any(strcmpi(parts{idx}, allowed_values))
            warning('%s 输入非法，保留默认值。', name);
            token = default_val;
            return;
        end
    end
    token = strjoin(parts, ',');
end

function value = local_ask_choice(name, default_val, choices)
    prompt = sprintf('%s [%s] options=%s: ', name, default_val, strjoin(choices, '/'));
    s = input(prompt, 's');
    if isempty(strtrim(s))
        value = default_val;
        return;
    end
    s = strtrim(s);
    hit = find(strcmpi(s, choices), 1);
    if isempty(hit)
        warning('%s 输入非法，保留默认值。', name);
        value = default_val;
    else
        value = choices{hit};
    end
end

function value = local_ask_yesno(name, default_val)
    if default_val
        default_token = 'y';
    else
        default_token = 'n';
    end
    s = input(sprintf('%s [y/n, default=%s]: ', name, default_token), 's');
    if isempty(strtrim(s))
        value = logical(default_val);
        return;
    end
    s = lower(strtrim(s));
    if any(strcmp(s, {'y', 'yes', '1'}))
        value = true;
    elseif any(strcmp(s, {'n', 'no', '0'}))
        value = false;
    else
        warning('%s 输入非法，保留默认值。', name);
        value = logical(default_val);
    end
end

function values = local_ask_vector(name, default_val)
    s = input(sprintf('%s %s: ', name, mat2str(default_val)), 's');
    if isempty(strtrim(s))
        values = default_val;
        return;
    end
    tmp = str2num(s); %#ok<ST2NM>
    if isempty(tmp)
        warning('%s 输入非法，保留默认值。', name);
        values = default_val;
    else
        values = reshape(tmp, 1, []);
    end
end

function parts = local_parse_csv_cell(token)
    raw = split(string(token), ',');
    raw = strtrim(raw);
    raw = raw(raw ~= "");
    if isempty(raw)
        parts = {'baseline'};
        return;
    end
    parts = cellstr(raw(:).');
end
