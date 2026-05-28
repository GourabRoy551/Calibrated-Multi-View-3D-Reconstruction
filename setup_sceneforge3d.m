function setup_sceneforge3d()
%SETUP_SCENEFORGE3D Configure paths and validate the local project layout.

    projectRoot = fileparts(mfilename('fullpath'));
    if isempty(projectRoot)
        projectRoot = pwd;
    end

    cd(projectRoot);
    addpath(genpath(fullfile(projectRoot, 'lib')));

    vlSetup = fullfile(projectRoot, 'vlfeat-0.9.21', 'toolbox', 'vl_setup.m');
    if exist(vlSetup, 'file')
        addpath(genpath(fullfile(projectRoot, 'vlfeat-0.9.21', 'toolbox')));
    end

    requiredFolders = ["images", "lib", "results"];
    for i = 1:numel(requiredFolders)
        folderPath = fullfile(projectRoot, requiredFolders(i));
        if ~exist(folderPath, 'dir')
            error('Missing required folder: %s', folderPath);
        end
    end

    requiredFiles = ["Roy_Gourab_1.m", "Roy_Gourab_2.m", "Roy_Gourab_3.m"];
    for i = 1:numel(requiredFiles)
        filePath = fullfile(projectRoot, requiredFiles(i));
        if ~exist(filePath, 'file')
            error('Missing required script: %s', filePath);
        end
    end

    fprintf('Calibrated Multi-View 3D Reconstruction setup complete.\n');
    fprintf('Project root: %s\n', projectRoot);

    if exist('detectSIFTFeatures', 'file')
        fprintf('MATLAB SIFT support: available.\n');
    else
        fprintf('MATLAB SIFT support: not found. Section 2 may need VLFeat MEX files.\n');
    end

    vlMexDir = fullfile(projectRoot, 'vlfeat-0.9.21', 'toolbox', 'mex', mexext);
    if exist(vlSetup, 'file') && exist(vlMexDir, 'dir')
        fprintf('VLFeat MEX support: available.\n');
    elseif exist(vlSetup, 'file')
        fprintf('VLFeat source/toolbox found, but compiled MEX files were not found for this platform.\n');
    else
        fprintf('VLFeat support: not found.\n');
    end
end
