function run_sceneforge3d(sectionName)
%RUN_SCENEFORGE3D Run the calibrated multi-view reconstruction pipeline.
%   RUN_SCENEFORGE3D runs all three project sections in order.
%   RUN_SCENEFORGE3D("section2") runs a single section.

    if nargin < 1 || strlength(string(sectionName)) == 0
        sectionName = "all";
    end

    sectionName = lower(string(sectionName));
    setup_sceneforge3d();

    fprintf('\nCalibrated Multi-View 3D Reconstruction pipeline\n');
    fprintf('Requested stage: %s\n\n', sectionName);

    switch sectionName
        case {"all", "full", "pipeline"}
            runSection("Roy_Gourab_1");
            runSection("Roy_Gourab_2");
            runSection("Roy_Gourab_3");
        case {"1", "section1", "calibration"}
            runSection("Roy_Gourab_1");
        case {"2", "section2", "matching"}
            runSection("Roy_Gourab_2");
        case {"3", "section3", "reconstruction"}
            runSection("Roy_Gourab_3");
        otherwise
            error('Unknown section "%s". Use all, section1, section2, or section3.', sectionName);
    end

    fprintf('\nCalibrated Multi-View 3D Reconstruction run complete. Results are in the results/ folder.\n');
end

function runSection(scriptName)
    scriptName = char(scriptName);
    fprintf('\n------------------------------------------------------\n');
    fprintf('Running %s.m\n', scriptName);
    fprintf('------------------------------------------------------\n');
    evalin('base', sprintf('run(''%s.m'')', scriptName));
end
