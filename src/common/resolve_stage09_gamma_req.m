function gamma_info = resolve_stage09_gamma_req(cfg)
%RESOLVE_STAGE09_GAMMA_REQ Resolve the scalar gamma_req used by Stage09 DG.
%
% Supported sources:
%   cfg.stage09.gamma_source = 'inherit_stage04'
%       Load the latest Stage04 cache and reuse out.summary.gamma_meta.gamma_req
%   cfg.stage09.gamma_source = 'manual'
%       Use cfg.stage09.gamma_req_manual

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage09_prepare_cfg(cfg);

    source_label = lower(string(cfg.stage09.gamma_source));

    switch source_label
        case "inherit_stage04"
            listing = find_stage_cache_files(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
            if isempty(listing)
                error(['resolve_stage09_gamma_req:NoStage04Cache ' ...
                    'No Stage04 cache found. Please run stage04_window_worstcase first.']);
            end

            [~, idx] = max([listing.datenum]);
            cache_file = fullfile(listing(idx).folder, listing(idx).name);
            S = load(cache_file);

            if ~isfield(S, 'out') || ~isstruct(S.out)
                error('resolve_stage09_gamma_req:InvalidStage04Cache Invalid Stage04 cache: %s', cache_file);
            end
            if ~isfield(S.out, 'summary') || ~isstruct(S.out.summary) || ...
                    ~isfield(S.out.summary, 'gamma_meta') || ~isstruct(S.out.summary.gamma_meta) || ...
                    ~isfield(S.out.summary.gamma_meta, 'gamma_req')
                error(['resolve_stage09_gamma_req:MissingGammaMeta ' ...
                    'Stage04 cache missing out.summary.gamma_meta.gamma_req: %s'], cache_file);
            end

            gamma_req = S.out.summary.gamma_meta.gamma_req;

        case "manual"
            if ~isfield(cfg.stage09, 'gamma_req_manual') || isempty(cfg.stage09.gamma_req_manual)
                error(['resolve_stage09_gamma_req:MissingManualGamma ' ...
                    'cfg.stage09.gamma_req_manual must be provided when gamma_source=manual.']);
            end

            gamma_req = cfg.stage09.gamma_req_manual;
            cache_file = "";

        otherwise
            error('resolve_stage09_gamma_req:UnknownSource Unsupported gamma_source: %s', string(cfg.stage09.gamma_source));
    end

    if ~isscalar(gamma_req) || ~isfinite(gamma_req) || gamma_req <= 0
        error('resolve_stage09_gamma_req:InvalidGamma gamma_req must be a finite positive scalar.');
    end

    gamma_info = struct();
    gamma_info.gamma_req = double(gamma_req);
    gamma_info.source_label = string(source_label);
    gamma_info.cache_file = string(cache_file);
end
