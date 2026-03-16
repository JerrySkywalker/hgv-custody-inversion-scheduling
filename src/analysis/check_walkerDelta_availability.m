function info = check_walkerDelta_availability()
%CHECK_WALKERDELTA_AVAILABILITY Check satelliteScenario / walkerDelta support.

info = struct();
info.satelliteScenario_available = (exist('satelliteScenario', 'file') == 2 || exist('satelliteScenario', 'class') == 8 || exist('satelliteScenario', 'file') == 6);
info.walkerDelta_available = (exist('walkerDelta', 'file') == 2 || exist('walkerDelta', 'class') == 8 || exist('walkerDelta', 'file') == 6);
info.is_available = info.satelliteScenario_available && info.walkerDelta_available;

if info.is_available
    info.message = "walkerDelta backend is available.";
else
    info.message = ['shared_scenarios requires Aerospace Toolbox walkerDelta support. ' ...
        'This environment has satelliteScenario=' char(string(info.satelliteScenario_available)) ...
        ', walkerDelta=' char(string(info.walkerDelta_available)) ...
        '. Install/use a MATLAB release with walkerDelta support (R2022a+ per MathWorks documentation).'];
end
end
