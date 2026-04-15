function suite = default_ch5r_suite_params()
%DEFAULT_CH5R_SUITE_PARAMS
% Preset case groups for Chapter 5 multi-case experiments.
%
% Phase 2A only:
% - registry / case list layer
% - no runner integration yet

suite = struct();

% -------------------------------
% Minimal smoke set
% -------------------------------
suite.case_sets = struct();

suite.case_sets.smoke = { ...
    'N01', 'N04', 'N09', ...
    'H01_+00', 'H04_+30', 'H09_-30', ...
    'C1_track_plane_aligned'};

% -------------------------------
% Paper-ready representative set
% -------------------------------
suite.case_sets.paper = { ...
    'N01', 'N03', 'N04', 'N06', 'N09', 'N12', ...
    'H01_+00', 'H02_+30', 'H04_-30', 'H07_+60', 'H09_-30', 'H12_+30', ...
    'C1_track_plane_aligned', 'C2_small_crossing_angle'};

% -------------------------------
% Family aliases
% -------------------------------
suite.family_alias = struct();
suite.family_alias.nominal = {'nominal'};
suite.family_alias.heading = {'heading'};
suite.family_alias.critical = {'critical'};

% -------------------------------
% Full registry counts (for smoke checks)
% -------------------------------
suite.expected_counts = struct();
suite.expected_counts.nominal = 12;
suite.expected_counts.heading = 60;
suite.expected_counts.critical = 2;
suite.expected_counts.total = 74;
end
