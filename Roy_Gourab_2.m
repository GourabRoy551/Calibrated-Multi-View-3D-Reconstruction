clear all; close all; clc;

% Section 2 studies local feature matching on the captured scene views.

addpath(genpath('./lib'));

% VLFeat was used in the labs, but the submitted folder may not contain the
% compiled MEX files for this MATLAB installation. When that happens, the
% script falls back to MATLAB's built-in SIFT implementation.
vl_setup_path = fullfile('vlfeat-0.9.21', 'toolbox', 'vl_setup.m');
vl_mex_dir = fullfile('vlfeat-0.9.21', 'toolbox', 'mex', mexext);
if exist(vl_setup_path, 'file') && exist(vl_mex_dir, 'dir')
    run(vl_setup_path);
else
    fprintf('VLFeat executable MEX files were not found. MATLAB built-in SIFT will be used if available.\n');
end

section_dir = fullfile('results', 'section_2');
if ~exist(section_dir, 'dir')
    mkdir(section_dir);
end

fprintf('======================================================\n');
fprintf('SECTION 2: FEATURE MATCHING\n');
fprintf('All report-ready outputs will be saved in %s\n', section_dir);
fprintf('======================================================\n\n');

scene_dir = fullfile('images', 'scene');
intrinsics_path = fullfile('results', 'section_1', 'A_screen.mat');
max_image_width = 1024;

% Section 2 uses the camera calibrated in Section 1. If the images are
% resized for speed, the intrinsic matrix is scaled inside readSceneImages.
if ~exist(intrinsics_path, 'file')
    error('Missing Section 1 intrinsic matrix: %s. Run Roy_Gourab_1.m first.', intrinsics_path);
end

intrinsics = load(intrinsics_path, 'A');
A = intrinsics.A;

scene_files = listImageFiles(scene_dir);
if numel(scene_files) < 4
    error('Section 2 needs at least 4 scene images in %s. Recommended: 6 to 10 images.', scene_dir);
end

[images_rgb, images_gray, scene] = readSceneImages(scene_dir, scene_files, max_image_width, A);
saveMontage(images_rgb, fullfile(section_dir, 'scene_montage.png'));

% The assignment does not require testing every possible image pair. These
% pairs cover adjacent, medium-baseline, and wider-baseline cases.
pairs = selectRepresentativePairs(numel(images_rgb), scene.image_names);
setups = buildFeatureSetups();
if numel(setups) < 3
    warning('Only %d matching setups are available. The report should explain this toolbox limitation.', numel(setups));
end

fprintf('Evaluating %d image pairs across %d feature setups...\n', numel(pairs), numel(setups));
results = struct([]);
row_idx = 0;

% Evaluate every selected pair with every available feature setup. For each
% case we keep both the raw matching data and the geometry-quality metrics.
for p = 1:numel(pairs)
    pair = pairs(p);
    I1 = images_rgb{pair.i};
    I2 = images_rgb{pair.j};
    G1 = images_gray{pair.i};
    G2 = images_gray{pair.j};

    fprintf('\nPair %d/%d: %s vs %s (%s)\n', p, numel(pairs), pair.name_i, pair.name_j, pair.reason);

    for s = 1:numel(setups)
        setup = setups(s);
        fprintf('  Setup: %s... ', setup.name);

        timer_start = tic;
        feature_result = runFeatureSetup(G1, G2, setup);
        geometry_result = evaluateGeometry(feature_result.points1, feature_result.points2);
        runtime_seconds = toc(timer_start);

        row_idx = row_idx + 1;
        results(row_idx).pair_index = p;
        results(row_idx).pair_i = pair.i;
        results(row_idx).pair_j = pair.j;
        results(row_idx).pair_name = sprintf('%s vs %s', pair.name_i, pair.name_j);
        results(row_idx).pair_reason = pair.reason;
        results(row_idx).setup_name = setup.name;
        results(row_idx).setup_method = setup.method;
        results(row_idx).keypoints_1 = feature_result.keypoints1;
        results(row_idx).keypoints_2 = feature_result.keypoints2;
        results(row_idx).raw_matches = feature_result.raw_matches;
        results(row_idx).points1 = feature_result.points1;
        results(row_idx).points2 = feature_result.points2;
        results(row_idx).match_scores = feature_result.scores;
        results(row_idx).homography_valid = geometry_result.homography_valid;
        results(row_idx).homography = geometry_result.H;
        results(row_idx).homography_tform = geometry_result.tform;
        results(row_idx).homography_inliers = geometry_result.h_inliers_count;
        results(row_idx).homography_inlier_ratio = geometry_result.h_inlier_ratio;
        results(row_idx).homography_residual = geometry_result.h_residual;
        results(row_idx).homography_inlier_mask = geometry_result.h_inliers;
        results(row_idx).fundamental_valid = geometry_result.fundamental_valid;
        results(row_idx).fundamental_matrix = geometry_result.F;
        results(row_idx).fundamental_inliers = geometry_result.f_inliers_count;
        results(row_idx).fundamental_inlier_ratio = geometry_result.f_inlier_ratio;
        results(row_idx).fundamental_error = geometry_result.f_error;
        results(row_idx).fundamental_inlier_mask = geometry_result.f_inliers;
        results(row_idx).runtime_seconds = runtime_seconds;
        results(row_idx).status = geometry_result.status;

        fprintf('%d matches, H inliers %d, F inliers %d, F error %.4g\n', ...
            results(row_idx).raw_matches, ...
            results(row_idx).homography_inliers, ...
            results(row_idx).fundamental_inliers, ...
            results(row_idx).fundamental_error);
    end
end

% The best result is chosen mainly by fundamental-matrix support, with the
% homography score used as secondary evidence of correspondence quality.
best_indices = selectBestResults(results, 4);
if isempty(best_indices)
    error('No valid feature-matching setup produced a usable homography or fundamental matrix.');
end

best = results(best_indices(1));
top_results = results(best_indices);

fprintf('\nBest setup: %s on %s\n', best.setup_name, best.pair_name);

best_I1 = images_rgb{best.pair_i};
best_I2 = images_rgb{best.pair_j};
best_pair = pairs(best.pair_index);
best_match_mask = chooseBestInlierMask(best);

% Save the figures and matrices requested for the best pair in LabFinal.pdf.
saveBestMatchFigure(best_I1, best_I2, best.points1, best.points2, best_match_mask, ...
    fullfile(section_dir, 'best_matches.png'), sprintf('Best matches: %s, %s', best.pair_name, best.setup_name));

if best.homography_valid
    panorama = createPanorama(best_I1, best_I2, best.homography_tform);
    imwrite(panorama, fullfile(section_dir, 'best_panorama.png'));
else
    savePlaceholderImage(fullfile(section_dir, 'best_panorama.png'), 'No valid homography was available for panorama generation.');
end

writeMatrixFile(fullfile(section_dir, 'best_homography.txt'), best.homography, 'Best homography H');
writeMatrixFile(fullfile(section_dir, 'best_fundamental_matrix.txt'), best.fundamental_matrix, 'Best fundamental matrix F');

if best.fundamental_valid
    saveEpipolarInspectionFigure(best_I1, best_I2, best.points1, best.points2, best.fundamental_matrix, best.fundamental_inlier_mask, ...
        fullfile(section_dir, 'vgg_gui_F_best_pair.png'));
else
    savePlaceholderImage(fullfile(section_dir, 'vgg_gui_F_best_pair.png'), 'No valid fundamental matrix was available for epipolar inspection.');
end

% The PDF asks for a real vgg_gui_F screenshot. This text file records the
% exact MATLAB commands used to open the GUI for the selected best pair.
writeVggGuiInstructions(fullfile(section_dir, 'vgg_gui_F_instructions.txt'), best_pair, best);

% Per-octave SIFT is included because the assignment asks how octave filtering
% changes matching performance.
octave_results = runSiftOctaveExperiment(images_gray{best.pair_i}, images_gray{best.pair_j});
saveOctaveFigure(octave_results, fullfile(section_dir, 'per_octave_results.png'));
saveOctaveMatchFigure(images_gray{best.pair_i}, images_gray{best.pair_j}, ...
    images_rgb{best.pair_i}, images_rgb{best.pair_j}, octave_results, ...
    fullfile(section_dir, 'octave0_matches.png'));

writeComparisonCsv(fullfile(section_dir, 'setup_comparison.csv'), results);
writeReportValues(fullfile(section_dir, 'section2_report_values.txt'), scene, pairs, setups, results, top_results, best, octave_results);

% Store the full MATLAB workspace summary for later inspection and for
% Section 3, which reuses the best pair and detector choice from Section 2.
section2 = struct();
section2.scene = scene;
section2.pairs = pairs;
section2.setups = setups;
section2.results = results;
section2.top_results = top_results;
section2.best = best;
section2.octave_results = octave_results;
section2.figure_paths.scene_montage = fullfile(section_dir, 'scene_montage.png');
section2.figure_paths.best_matches = fullfile(section_dir, 'best_matches.png');
section2.figure_paths.best_panorama = fullfile(section_dir, 'best_panorama.png');
section2.figure_paths.per_octave = fullfile(section_dir, 'per_octave_results.png');
section2.figure_paths.octave0_matches = fullfile(section_dir, 'octave0_matches.png');
section2.figure_paths.vgg_gui_F = fullfile(section_dir, 'vgg_gui_F_best_pair.png');

save(fullfile(section_dir, 'section2_metrics.mat'), 'section2');
save(fullfile(section_dir, 'best_pair_data.mat'), 'best', 'best_pair');

fprintf('\n>>> Section 2 coding outputs complete. <<<\n');
fprintf('Saved figures, matrices, tables, and report values to %s\n', section_dir);
fprintf('If an exact vgg_gui_F GUI screenshot is required, follow %s\n', fullfile(section_dir, 'vgg_gui_F_instructions.txt'));

function files = listImageFiles(folder_path)
    % Collect common image formats and sort them so repeated runs process the
    % scene views in the same order.
    files = [dir(fullfile(folder_path, '*.jpg')); ...
             dir(fullfile(folder_path, '*.JPG')); ...
             dir(fullfile(folder_path, '*.jpeg')); ...
             dir(fullfile(folder_path, '*.JPEG')); ...
             dir(fullfile(folder_path, '*.png')); ...
             dir(fullfile(folder_path, '*.PNG')); ...
             dir(fullfile(folder_path, '*.bmp')); ...
             dir(fullfile(folder_path, '*.BMP'))];
    if isempty(files)
        return;
    end
    [~, unique_idx] = unique(lower({files.name}), 'stable');
    files = files(unique_idx);
    [~, order] = sort(lower({files.name}));
    files = files(order);
end

function [images_rgb, images_gray, scene] = readSceneImages(scene_dir, scene_files, max_width, A)
    % Read the captured scene images and resize them to a common maximum width.
    % The same scale factor is applied to the first two rows of A, following
    % the image-resizing note in LabFinal.pdf.
    n = numel(scene_files);
    images_rgb = cell(1, n);
    images_gray = cell(1, n);
    image_paths = cell(1, n);
    image_names = cell(1, n);
    original_sizes = zeros(n, 2);
    resized_sizes = zeros(n, 2);
    scale_factors = ones(n, 1);

    for i = 1:n
        image_paths{i} = fullfile(scene_dir, scene_files(i).name);
        image_names{i} = scene_files(i).name;
        I = imread(image_paths{i});
        if size(I, 3) == 1
            I = repmat(I, [1 1 3]);
        end

        original_sizes(i, :) = [size(I, 2), size(I, 1)];
        scale = 1;
        if size(I, 2) > max_width
            scale = max_width / size(I, 2);
            I = imresize(I, scale);
        end

        resized_sizes(i, :) = [size(I, 2), size(I, 1)];
        scale_factors(i) = scale;
        images_rgb{i} = I;
        images_gray{i} = rgb2gray(I);
    end

    A_scaled_per_image = zeros(3, 3, n);
    for i = 1:n
        A_i = A;
        A_i(1:2, :) = scale_factors(i) * A_i(1:2, :);
        A_scaled_per_image(:, :, i) = A_i;
    end

    scene = struct();
    scene.image_files = image_paths;
    scene.image_names = image_names;
    scene.original_sizes = original_sizes;
    scene.resized_sizes = resized_sizes;
    scene.scale_factors = scale_factors;
    scene.max_image_width = max_width;
    scene.A_original = A;
    scene.A_used = A_scaled_per_image(:, :, 1);
    scene.A_scaled_per_image = A_scaled_per_image;
    scene.has_mixed_orientation = size(unique(original_sizes, 'rows'), 1) > 1;
    scene.description = 'Scene views captured with the calibrated camera from Section 1.';
end

function saveMontage(images_rgb, output_path)
    % A single montage is useful in the report to show the full scene dataset.
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    montage(images_rgb, 'Size', [NaN 3]);
    cleanAxesForExport(gca);
    title('Section 2 scene image montage');
    saveFigure(fig, output_path);
    close(fig);
end

function pairs = selectRepresentativePairs(n_images, image_names)
    % Pick a small but representative set instead of all possible pairs:
    % adjacent views for overlap, plus wider pairs for viewpoint robustness.
    candidates = [1 2; 2 3; 1 ceil(n_images / 2); max(1, n_images - 2) n_images; 1 n_images];
    reasons = {'adjacent views', 'adjacent views', 'medium baseline', 'medium/wide baseline', 'widest available baseline'};
    valid = candidates(:, 1) >= 1 & candidates(:, 2) <= n_images & candidates(:, 1) < candidates(:, 2);
    candidates = candidates(valid, :);
    reasons = reasons(valid);
    [candidates, unique_idx] = unique(candidates, 'rows', 'stable');
    reasons = reasons(unique_idx);

    pairs = struct([]);
    for k = 1:size(candidates, 1)
        pairs(k).i = candidates(k, 1);
        pairs(k).j = candidates(k, 2);
        pairs(k).name_i = image_names{pairs(k).i};
        pairs(k).name_j = image_names{pairs(k).j};
        pairs(k).reason = reasons{k};
    end
end

function setups = buildFeatureSetups()
    % Build the list of detectors/descriptors available on this machine.
    % Keeping all settings here makes the setup comparison easy to audit.
    setups = struct([]);
    idx = 0;

    if canUseVlSift()
        idx = idx + 1;
        setups(idx).name = 'SIFT VLFeat default';
        setups(idx).method = 'SIFT';
        setups(idx).match_threshold = 1.5;
        setups(idx).max_ratio = 0.75;
        setups(idx).max_features = inf;

        idx = idx + 1;
        setups(idx).name = 'SIFT VLFeat strict';
        setups(idx).method = 'SIFT';
        setups(idx).match_threshold = 1.2;
        setups(idx).max_ratio = 0.60;
        setups(idx).max_features = inf;
    elseif exist('detectSIFTFeatures', 'file')
        idx = idx + 1;
        setups(idx).name = 'SIFT MATLAB default';
        setups(idx).method = 'SIFT_MATLAB';
        setups(idx).match_threshold = 40;
        setups(idx).max_ratio = 0.75;
        setups(idx).max_features = 2000;

        idx = idx + 1;
        setups(idx).name = 'SIFT MATLAB strict';
        setups(idx).method = 'SIFT_MATLAB';
        setups(idx).match_threshold = 30;
        setups(idx).max_ratio = 0.60;
        setups(idx).max_features = inf;
    end

    if exist('detectSURFFeatures', 'file')
        idx = idx + 1;
        setups(idx).name = 'SURF matchFeatures';
        setups(idx).method = 'SURF';
        setups(idx).match_threshold = 40;
        setups(idx).max_ratio = 0.75;
        setups(idx).max_features = 1500;
    end

    if exist('detectORBFeatures', 'file')
        idx = idx + 1;
        setups(idx).name = 'ORB matchFeatures';
        setups(idx).method = 'ORB';
        setups(idx).match_threshold = 40;
        setups(idx).max_ratio = 0.75;
        setups(idx).max_features = 1500;
    elseif exist('detectKAZEFeatures', 'file')
        idx = idx + 1;
        setups(idx).name = 'KAZE matchFeatures';
        setups(idx).method = 'KAZE';
        setups(idx).match_threshold = 40;
        setups(idx).max_ratio = 0.75;
        setups(idx).max_features = 1500;
    end
end

function tf = canUseVlSift()
    % VLFeat functions can exist as .m wrappers without the matching MEX files.
    % This check avoids calling VLFeat unless the compiled functions are ready.
    sift_path = which('vl_sift');
    match_path = which('vl_ubcmatch');
    if isempty(sift_path) || isempty(match_path)
        tf = false;
        return;
    end
    [~, ~, sift_ext] = fileparts(sift_path);
    [~, ~, match_ext] = fileparts(match_path);
    tf = strcmpi(sift_ext, ['.' mexext]) && strcmpi(match_ext, ['.' mexext]);
end

function feature_result = runFeatureSetup(G1, G2, setup)
    % Detect, describe, and match features for one pair and one setup.
    % Geometry is evaluated later so the feature code stays independent.
    feature_result = emptyFeatureResult();

    switch setup.method
        case 'SIFT'
            [f1, d1] = vl_sift(single(G1));
            [f2, d2] = vl_sift(single(G2));
            feature_result.keypoints1 = size(f1, 2);
            feature_result.keypoints2 = size(f2, 2);
            if isempty(d1) || isempty(d2)
                return;
            end
            [matches, scores] = vl_ubcmatch(d1, d2, setup.match_threshold);
            feature_result.raw_matches = size(matches, 2);
            feature_result.points1 = f1(1:2, matches(1, :))';
            feature_result.points2 = f2(1:2, matches(2, :))';
            feature_result.scores = scores(:);

        case {'SIFT_MATLAB', 'SURF', 'ORB', 'KAZE'}
            [points1, features1] = detectAndDescribe(G1, setup.method, setup.max_features);
            [points2, features2] = detectAndDescribe(G2, setup.method, setup.max_features);
            feature_result.keypoints1 = size(points1, 1);
            feature_result.keypoints2 = size(points2, 1);
            if isempty(points1) || isempty(points2) || isempty(features1) || isempty(features2)
                return;
            end
            pairs = matchFeatures(features1, features2, 'Unique', true, 'MaxRatio', setup.max_ratio, 'MatchThreshold', setup.match_threshold);
            feature_result.raw_matches = size(pairs, 1);
            feature_result.points1 = points1(pairs(:, 1), :);
            feature_result.points2 = points2(pairs(:, 2), :);
            feature_result.scores = zeros(feature_result.raw_matches, 1);
    end
end

function feature_result = emptyFeatureResult()
    % Standard empty result used when a detector finds no usable matches.
    feature_result = struct();
    feature_result.keypoints1 = 0;
    feature_result.keypoints2 = 0;
    feature_result.raw_matches = 0;
    feature_result.points1 = zeros(0, 2);
    feature_result.points2 = zeros(0, 2);
    feature_result.scores = [];
end

function [locations, features] = detectAndDescribe(G, method, max_features)
    % MATLAB detectors return feature-point objects; this helper converts them
    % into plain coordinate/descriptor arrays for matchFeatures.
    switch method
        case 'SIFT_MATLAB'
            points = detectSIFTFeatures(G);
        case 'SURF'
            points = detectSURFFeatures(G);
        case 'ORB'
            points = detectORBFeatures(G);
        case 'KAZE'
            points = detectKAZEFeatures(G);
    end

    if points.Count == 0
        locations = zeros(0, 2);
        features = [];
        return;
    end

    if isfinite(max_features)
        points = points.selectStrongest(min(max_features, points.Count));
    end
    [features, valid_points] = extractFeatures(G, points);
    locations = valid_points.Location;
end

function geometry = evaluateGeometry(points1, points2)
    % Estimate both planar and epipolar geometry. The homography is useful for
    % panorama generation, while the fundamental matrix is the main 3D cue.
    geometry = struct();
    geometry.homography_valid = false;
    geometry.H = nan(3, 3);
    geometry.tform = projective2d(eye(3));
    geometry.h_inliers = false(size(points1, 1), 1);
    geometry.h_inliers_count = 0;
    geometry.h_inlier_ratio = 0;
    geometry.h_residual = inf;
    geometry.fundamental_valid = false;
    geometry.F = nan(3, 3);
    geometry.f_inliers = false(size(points1, 1), 1);
    geometry.f_inliers_count = 0;
    geometry.f_inlier_ratio = 0;
    geometry.f_error = inf;
    geometry.status = 'not enough matches';

    n_matches = size(points1, 1);
    if n_matches < 4
        return;
    end

    try
        [tform, h_inliers] = estimateGeometricTransform2D(points1, points2, 'projective', ...
            'MaxNumTrials', 2000, 'Confidence', 99, 'MaxDistance', 4);
        geometry.homography_valid = true;
        geometry.tform = tform;
        geometry.H = tform.T';
        geometry.h_inliers = h_inliers;
        geometry.h_inliers_count = nnz(h_inliers);
        geometry.h_inlier_ratio = nnz(h_inliers) / n_matches;
        projected = transformPointsForward(tform, points1(h_inliers, :));
        residuals = sqrt(sum((projected - points2(h_inliers, :)).^2, 2));
        geometry.h_residual = mean(residuals);
        geometry.status = 'homography ok';
    catch ME
        geometry.status = sprintf('homography failed: %s', ME.message);
    end

    if n_matches < 8
        return;
    end

    try
        [F, f_inliers] = estimateFundamentalMatrix(points1, points2, ...
            'Method', 'RANSAC', 'NumTrials', 3000, 'DistanceThreshold', 1.0, 'Confidence', 99);
        geometry.fundamental_valid = true;
        geometry.F = F;
        geometry.f_inliers = f_inliers;
        geometry.f_inliers_count = nnz(f_inliers);
        geometry.f_inlier_ratio = nnz(f_inliers) / n_matches;
        geometry.f_error = meanSampsonDistance(F, points1(f_inliers, :), points2(f_inliers, :));
        geometry.status = 'homography and fundamental matrix ok';
    catch ME
        geometry.status = sprintf('%s; fundamental failed: %s', geometry.status, ME.message);
    end
end

function d = meanSampsonDistance(F, points1, points2)
    % Sampson distance gives a compact numerical check of the epipolar fit.
    if isempty(points1) || isempty(points2) || any(~isfinite(F(:)))
        d = inf;
        return;
    end

    x1 = [points1, ones(size(points1, 1), 1)]';
    x2 = [points2, ones(size(points2, 1), 1)]';
    Fx1 = F * x1;
    Ftx2 = F' * x2;
    numerator = sum(x2 .* Fx1, 1).^2;
    denominator = Fx1(1, :).^2 + Fx1(2, :).^2 + Ftx2(1, :).^2 + Ftx2(2, :).^2;
    vals = numerator ./ max(denominator, eps);
    d = mean(vals);
end

function best_indices = selectBestResults(results, k)
    % Rank setups with a simple, transparent score. Fundamental-matrix inliers
    % are weighted most because they are the most relevant for Sections 2 and 3.
    if isempty(results)
        best_indices = [];
        return;
    end

    scores = -inf(1, numel(results));
    for i = 1:numel(results)
        f_bonus = 0;
        if results(i).fundamental_valid
            f_bonus = 100000 + results(i).fundamental_inliers * 100 - results(i).fundamental_error;
        end
        h_bonus = 0;
        if results(i).homography_valid
            h_bonus = results(i).homography_inliers * 10 - results(i).homography_residual;
        end
        scores(i) = f_bonus + h_bonus + results(i).raw_matches * 0.01;
    end

    [~, order] = sort(scores, 'descend');
    order = order(isfinite(scores(order)));
    best_indices = order(1:min(k, numel(order)));
end

function mask = chooseBestInlierMask(result)
    % Prefer F inliers for the report figure because the selected best pair is
    % ultimately used for epipolar geometry and reconstruction.
    if result.fundamental_valid && any(result.fundamental_inlier_mask)
        mask = result.fundamental_inlier_mask;
    elseif result.homography_valid && any(result.homography_inlier_mask)
        mask = result.homography_inlier_mask;
    else
        mask = true(size(result.points1, 1), 1);
    end
end

function saveBestMatchFigure(I1, I2, points1, points2, mask, output_path, fig_title)
    % Save a clean correspondence overlay for the report.
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    if isempty(points1)
        imshow([I1, I2]);
        title('No matches available');
    else
        showMatchedFeatures(I1, I2, points1(mask, :), points2(mask, :), 'montage', 'PlotOptions', {'go', 'r+', 'y-'});
        title(fig_title);
    end
    cleanAxesForExport(gca);
    saveFigure(fig, output_path);
    close(fig);
end

function panorama = createPanorama(I1, I2, tform)
    % Warp the first image into the second image coordinate system and blend
    % their overlap. This is intentionally simple and reproducible.
    [xlim1, ylim1] = outputLimits(tform, [1 size(I1, 2)], [1 size(I1, 1)]);
    xlim2 = [1 size(I2, 2)];
    ylim2 = [1 size(I2, 1)];
    x_min = floor(min([xlim1 xlim2]));
    x_max = ceil(max([xlim1 xlim2]));
    y_min = floor(min([ylim1 ylim2]));
    y_max = ceil(max([ylim1 ylim2]));

    panorama_ref = imref2d([y_max - y_min + 1, x_max - x_min + 1], [x_min x_max], [y_min y_max]);
    I1_warp = imwarp(I1, tform, 'OutputView', panorama_ref);
    I2_warp = imwarp(I2, projective2d(eye(3)), 'OutputView', panorama_ref);
    mask1 = imwarp(true(size(I1, 1), size(I1, 2)), tform, 'OutputView', panorama_ref);
    mask2 = imwarp(true(size(I2, 1), size(I2, 2)), projective2d(eye(3)), 'OutputView', panorama_ref);

    panorama = I2_warp;
    only1 = mask1 & ~mask2;
    both = mask1 & mask2;
    for c = 1:size(panorama, 3)
        chan = panorama(:, :, c);
        chan1 = I1_warp(:, :, c);
        chan2 = I2_warp(:, :, c);
        chan(only1) = chan1(only1);
        chan(both) = uint8(0.5 * double(chan1(both)) + 0.5 * double(chan2(both)));
        panorama(:, :, c) = chan;
    end
end

function saveEpipolarInspectionFigure(I1, I2, points1, points2, F, inlier_mask, output_path)
    % This automatic figure is a quick epipolar sanity check. The assignment
    % still asks for a separate manual screenshot of the real vgg_gui_F GUI.
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    canvas = makeSideBySideCanvas(I1, I2);
    imshow(canvas);
    hold on;

    if isempty(inlier_mask) || ~any(inlier_mask)
        inlier_mask = true(size(points1, 1), 1);
    end
    inlier_idx = find(inlier_mask);
    inlier_idx = inlier_idx(1:min(12, numel(inlier_idx)));
    sample_pts1 = points1(inlier_idx, :);
    sample_pts2 = points2(inlier_idx, :);
    offset_x = size(I1, 2);

    plot(sample_pts1(:, 1), sample_pts1(:, 2), 'go', 'MarkerSize', 7, 'LineWidth', 1.5);
    plot(sample_pts2(:, 1) + offset_x, sample_pts2(:, 2), 'r+', 'MarkerSize', 7, 'LineWidth', 1.5);

    lines2 = epipolarLine(F, sample_pts1);
    border_points = lineToBorderPoints(lines2, size(I2));
    for k = 1:size(border_points, 1)
        line([border_points(k, 1) border_points(k, 3)] + offset_x, ...
             [border_points(k, 2) border_points(k, 4)], 'Color', 'y', 'LineWidth', 1);
    end
    title('Epipolar inspection for best fundamental matrix');
    hold off;
    cleanAxesForExport(gca);
    saveFigure(fig, output_path);
    close(fig);
end

function canvas = makeSideBySideCanvas(I1, I2)
    % Build a single canvas so epipolar lines can be drawn across the montage.
    h = max(size(I1, 1), size(I2, 1));
    w = size(I1, 2) + size(I2, 2);
    canvas = zeros(h, w, 3, 'uint8');
    canvas(1:size(I1, 1), 1:size(I1, 2), :) = I1;
    canvas(1:size(I2, 1), size(I1, 2) + 1:end, :) = I2;
end

function octave_results = runSiftOctaveExperiment(G1, G2)
    % Dispatch to the SIFT implementation available on the current MATLAB setup.
    octave_results = struct([]);
    if canUseVlSift()
        octave_results = runVlSiftOctaveExperiment(G1, G2);
    elseif exist('detectSIFTFeatures', 'file')
        octave_results = runMatlabSiftOctaveExperiment(G1, G2);
    end
end

function octave_results = runVlSiftOctaveExperiment(G1, G2)
    % Group VLFeat SIFT descriptors by scale octave and repeat matching within
    % each group to show how scale filtering affects the result.
    octave_results = struct([]);
    [f1, d1] = vl_sift(single(G1));
    [f2, d2] = vl_sift(single(G2));
    oct1 = floor(log2(max(f1(3, :), eps)));
    oct2 = floor(log2(max(f2(3, :), eps)));
    octaves = intersect(unique(oct1), unique(oct2));

    for k = 1:numel(octaves)
        octave = octaves(k);
        idx1 = find(oct1 == octave);
        idx2 = find(oct2 == octave);
        points1 = zeros(0, 2);
        points2 = zeros(0, 2);
        raw_matches = 0;

        if ~isempty(idx1) && ~isempty(idx2)
            [matches, ~] = vl_ubcmatch(d1(:, idx1), d2(:, idx2), 1.5);
            raw_matches = size(matches, 2);
            if raw_matches > 0
                points1 = f1(1:2, idx1(matches(1, :)))';
                points2 = f2(1:2, idx2(matches(2, :)))';
            end
        end

        geom = evaluateGeometry(points1, points2);
        octave_results(k).octave = octave;
        octave_results(k).keypoints_1 = numel(idx1);
        octave_results(k).keypoints_2 = numel(idx2);
        octave_results(k).raw_matches = raw_matches;
        octave_results(k).homography_inliers = geom.h_inliers_count;
        octave_results(k).homography_residual = geom.h_residual;
        octave_results(k).fundamental_inliers = geom.f_inliers_count;
        octave_results(k).fundamental_error = geom.f_error;
    end
end

function octave_results = runMatlabSiftOctaveExperiment(G1, G2)
    % MATLAB SIFT does not expose the exact VLFeat octave field, so the octave
    % groups are approximated from the detected feature scale.
    octave_results = struct([]);
    points1_obj = detectSIFTFeatures(G1);
    points2_obj = detectSIFTFeatures(G2);
    if points1_obj.Count == 0 || points2_obj.Count == 0
        return;
    end

    points1_obj = points1_obj.selectStrongest(min(2000, points1_obj.Count));
    points2_obj = points2_obj.selectStrongest(min(2000, points2_obj.Count));
    [features1, valid1] = extractFeatures(G1, points1_obj);
    [features2, valid2] = extractFeatures(G2, points2_obj);

    loc1 = valid1.Location;
    loc2 = valid2.Location;
    oct1 = floor(log2(max(valid1.Scale, eps)));
    oct2 = floor(log2(max(valid2.Scale, eps)));
    octaves = intersect(unique(oct1), unique(oct2));

    for k = 1:numel(octaves)
        octave = octaves(k);
        idx1 = find(oct1 == octave);
        idx2 = find(oct2 == octave);
        points1 = zeros(0, 2);
        points2 = zeros(0, 2);
        raw_matches = 0;

        if ~isempty(idx1) && ~isempty(idx2)
            matches = matchFeatures(features1(idx1, :), features2(idx2, :), 'Unique', true, 'MaxRatio', 0.75, 'MatchThreshold', 40);
            raw_matches = size(matches, 1);
            if raw_matches > 0
                points1 = loc1(idx1(matches(:, 1)), :);
                points2 = loc2(idx2(matches(:, 2)), :);
            end
        end

        geom = evaluateGeometry(points1, points2);
        octave_results(k).octave = octave;
        octave_results(k).keypoints_1 = numel(idx1);
        octave_results(k).keypoints_2 = numel(idx2);
        octave_results(k).raw_matches = raw_matches;
        octave_results(k).homography_inliers = geom.h_inliers_count;
        octave_results(k).homography_residual = geom.h_residual;
        octave_results(k).fundamental_inliers = geom.f_inliers_count;
        octave_results(k).fundamental_error = geom.f_error;
    end
end

function saveOctaveFigure(octave_results, output_path)
    % Summarize raw matches, homography inliers, and F inliers for each octave.
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    if isempty(octave_results)
        text(0.1, 0.5, 'No SIFT octave results were available.', 'FontSize', 14);
        axis off;
    else
        octaves = [octave_results.octave];
        values = [[octave_results.raw_matches]' [octave_results.homography_inliers]' [octave_results.fundamental_inliers]'];
        bar(categorical(string(octaves)), values);
        legend({'Raw matches', 'H inliers', 'F inliers'}, 'Location', 'best');
        xlabel('SIFT octave group');
        ylabel('Count');
        title('Per-octave SIFT matching experiment');
        grid on;
    end
    cleanAxesForExport(gca);
    saveFigure(fig, output_path);
    close(fig);
end

function writeComparisonCsv(output_path, results)
    % Keep the full quantitative table in CSV so the report can include a
    % compact summary without losing the complete data.
    header = {'pair', 'reason', 'setup', 'keypoints_1', 'keypoints_2', 'raw_matches', ...
        'H_inliers', 'H_inlier_ratio', 'H_residual', 'F_inliers', 'F_inlier_ratio', ...
        'F_sampson_error', 'runtime_seconds', 'status'};
    rows = cell(numel(results) + 1, numel(header));
    rows(1, :) = header;
    for i = 1:numel(results)
        rows(i + 1, :) = {results(i).pair_name, results(i).pair_reason, results(i).setup_name, ...
            results(i).keypoints_1, results(i).keypoints_2, results(i).raw_matches, ...
            results(i).homography_inliers, results(i).homography_inlier_ratio, results(i).homography_residual, ...
            results(i).fundamental_inliers, results(i).fundamental_inlier_ratio, results(i).fundamental_error, ...
            results(i).runtime_seconds, results(i).status};
    end
    writecell(rows, output_path);
end

function writeReportValues(output_path, scene, pairs, setups, results, top_results, best, octave_results)
    % Write the exact values used in the report. This avoids copying numbers
    % manually from MATLAB's console output.
    fid = fopen(output_path, 'w');
    if fid == -1
        error('Could not open %s for writing.', output_path);
    end
    cleanup_obj = onCleanup(@() fclose(fid));

    fprintf(fid, 'SECTION 2 REPORT VALUES\n');
    fprintf(fid, '=======================\n\n');

    fprintf(fid, '2(a) Scene capture\n');
    fprintf(fid, '------------------\n');
    fprintf(fid, 'Scene images: %d\n', numel(scene.image_names));
    fprintf(fid, 'Original first image size: %d x %d px\n', scene.original_sizes(1, 1), scene.original_sizes(1, 2));
    fprintf(fid, 'Processed first image size: %d x %d px\n', scene.resized_sizes(1, 1), scene.resized_sizes(1, 2));
    fprintf(fid, 'Scale factor for first image: %.8f\n', scene.scale_factors(1));
    fprintf(fid, 'Mixed original image orientation/sizes: %d\n', scene.has_mixed_orientation);
    fprintf(fid, 'Scene montage: results/section_2/scene_montage.png\n');
    fprintf(fid, 'A_scaled_for_first_image =\n');
    writeMatrix(fid, scene.A_used);
    fprintf(fid, '\nPer-image scale factors:\n');
    for i = 1:numel(scene.image_names)
        fprintf(fid, '- %s | original %d x %d | processed %d x %d | scale %.8f\n', ...
            scene.image_names{i}, scene.original_sizes(i, 1), scene.original_sizes(i, 2), ...
            scene.resized_sizes(i, 1), scene.resized_sizes(i, 2), scene.scale_factors(i));
    end
    fprintf(fid, '\nScene image files:\n');
    writeCellList(fid, scene.image_names);

    fprintf(fid, '\nSelected pairs:\n');
    for i = 1:numel(pairs)
        fprintf(fid, '- Pair %d: %s vs %s (%s)\n', i, pairs(i).name_i, pairs(i).name_j, pairs(i).reason);
    end

    fprintf(fid, '\nFeature setups:\n');
    for i = 1:numel(setups)
        fprintf(fid, '- %s\n', setups(i).name);
    end

    fprintf(fid, '\n2(b) Pair/setup comparison\n');
    fprintf(fid, '--------------------------\n');
    fprintf(fid, 'Full table: results/section_2/setup_comparison.csv\n');
    for i = 1:numel(results)
        fprintf(fid, '%s | %s | keypoints %d/%d | matches %d | H inliers %d | H residual %.6f | F inliers %d | F error %.6f | runtime %.4f s\n', ...
            results(i).pair_name, results(i).setup_name, results(i).keypoints_1, results(i).keypoints_2, ...
            results(i).raw_matches, results(i).homography_inliers, results(i).homography_residual, ...
            results(i).fundamental_inliers, results(i).fundamental_error, results(i).runtime_seconds);
    end

    fprintf(fid, '\nTop four selected combinations:\n');
    for i = 1:numel(top_results)
        fprintf(fid, '%d. %s | %s | F inliers %d | F error %.6f | H inliers %d | H residual %.6f\n', ...
            i, top_results(i).pair_name, top_results(i).setup_name, top_results(i).fundamental_inliers, ...
            top_results(i).fundamental_error, top_results(i).homography_inliers, top_results(i).homography_residual);
    end

    fprintf(fid, '\nPer-octave SIFT experiment:\n');
    fprintf(fid, 'Figure: results/section_2/per_octave_results.png\n');
    if isempty(octave_results)
        fprintf(fid, 'No octave results available.\n');
    else
        for i = 1:numel(octave_results)
            fprintf(fid, 'Octave %d | keypoints %d/%d | matches %d | H inliers %d | F inliers %d | F error %.6f\n', ...
                octave_results(i).octave, octave_results(i).keypoints_1, octave_results(i).keypoints_2, ...
                octave_results(i).raw_matches, octave_results(i).homography_inliers, ...
                octave_results(i).fundamental_inliers, octave_results(i).fundamental_error);
        end
    end

    fprintf(fid, '\n2(c) Best combination\n');
    fprintf(fid, '---------------------\n');
    fprintf(fid, 'Best pair: %s\n', best.pair_name);
    fprintf(fid, 'Best setup: %s\n', best.setup_name);
    fprintf(fid, 'Raw matches: %d\n', best.raw_matches);
    fprintf(fid, 'Homography inliers: %d\n', best.homography_inliers);
    fprintf(fid, 'Homography residual: %.6f\n', best.homography_residual);
    fprintf(fid, 'Fundamental matrix inliers: %d\n', best.fundamental_inliers);
    fprintf(fid, 'Fundamental matrix Sampson error: %.6f\n', best.fundamental_error);
    fprintf(fid, 'Matched-points figure: results/section_2/best_matches.png\n');
    fprintf(fid, 'Panorama: results/section_2/best_panorama.png\n');
    fprintf(fid, 'Homography matrix: results/section_2/best_homography.txt\n');
    fprintf(fid, 'Fundamental matrix: results/section_2/best_fundamental_matrix.txt\n');
    fprintf(fid, 'Epipolar/vgg_gui_F figure: results/section_2/vgg_gui_F_best_pair.png\n');
end

function writeMatrix(fid, M)
    % Small helper for readable text files.
    for r = 1:size(M, 1)
        fprintf(fid, '  ');
        fprintf(fid, '%14.6f ', M(r, :));
        fprintf(fid, '\n');
    end
end

function writeCellList(fid, values)
    % Print one report item per line.
    for i = 1:numel(values)
        fprintf(fid, '- %s\n', values{i});
    end
end

function writeMatrixFile(output_path, M, label)
    % Save homography/F matrices in a format that can be pasted into the report.
    fid = fopen(output_path, 'w');
    if fid == -1
        error('Could not open %s for writing.', output_path);
    end
    cleanup_obj = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', label);
    fprintf(fid, '====================\n');
    if isempty(M) || any(~isfinite(M(:)))
        fprintf(fid, 'No valid matrix available.\n');
    else
        writeMatrix(fid, M);
    end
end

function writeVggGuiInstructions(output_path, best_pair, best)
    % The GUI screenshot is manual by nature, so the script records the exact
    % commands needed to recreate it for the selected best pair.
    fid = fopen(output_path, 'w');
    if fid == -1
        error('Could not open %s for writing.', output_path);
    end
    cleanup_obj = onCleanup(@() fclose(fid));
    fprintf(fid, 'To capture the exact vgg_gui_F GUI for the report, run this after Roy_Gourab_2.m finishes:\n\n');
    fprintf(fid, 'load(''results/section_2/section2_metrics.mat'');\n');
    fprintf(fid, 'I1 = imread(section2.scene.image_files{%d});\n', best_pair.i);
    fprintf(fid, 'I2 = imread(section2.scene.image_files{%d});\n', best_pair.j);
    fprintf(fid, 'F = section2.best.fundamental_matrix;\n');
    fprintf(fid, 'vgg_gui_F(I1, I2, F);\n\n');
    fprintf(fid, 'Best pair: %s\n', best.pair_name);
    fprintf(fid, 'Best setup: %s\n', best.setup_name);
end

function savePlaceholderImage(output_path, message)
    % If a required result cannot be produced, save an explicit placeholder
    % instead of silently leaving a missing file.
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    text(0.1, 0.5, message, 'FontSize', 14, 'Interpreter', 'none');
    axis off;
    saveFigure(fig, output_path);
    close(fig);
end

function saveOctaveMatchFigure(G1, G2, I1_rgb, I2_rgb, octave_results, output_path)
    % Save one example correspondence plot from the octave with the most
    % matches. This helps explain the per-octave experiment visually.
    if isempty(octave_results)
        savePlaceholderImage(output_path, 'No SIFT octave results available.');
        return;
    end

    [~, dom_idx] = max([octave_results.raw_matches]);
    dom_octave = octave_results(dom_idx).octave;

    points1 = zeros(0, 2);
    points2 = zeros(0, 2);
    f_inliers = false(0, 1);

    if canUseVlSift()
        [f1, d1] = vl_sift(single(G1));
        [f2, d2] = vl_sift(single(G2));
        oct1 = floor(log2(max(f1(3, :), eps)));
        oct2 = floor(log2(max(f2(3, :), eps)));
        idx1 = find(oct1 == dom_octave);
        idx2 = find(oct2 == dom_octave);
        if ~isempty(idx1) && ~isempty(idx2)
            [matches, ~] = vl_ubcmatch(d1(:, idx1), d2(:, idx2), 1.5);
            if size(matches, 2) > 0
                points1 = f1(1:2, idx1(matches(1, :)))';
                points2 = f2(1:2, idx2(matches(2, :)))';
            end
        end
    elseif exist('detectSIFTFeatures', 'file')
        pts1_obj = detectSIFTFeatures(G1);
        pts2_obj = detectSIFTFeatures(G2);
        pts1_obj = pts1_obj.selectStrongest(min(2000, pts1_obj.Count));
        pts2_obj = pts2_obj.selectStrongest(min(2000, pts2_obj.Count));
        [feat1, valid1] = extractFeatures(G1, pts1_obj);
        [feat2, valid2] = extractFeatures(G2, pts2_obj);
        oct1 = floor(log2(max(valid1.Scale, eps)));
        oct2 = floor(log2(max(valid2.Scale, eps)));
        idx1 = find(oct1 == dom_octave);
        idx2 = find(oct2 == dom_octave);
        if ~isempty(idx1) && ~isempty(idx2)
            matches = matchFeatures(feat1(idx1, :), feat2(idx2, :), 'Unique', true, 'MaxRatio', 0.75, 'MatchThreshold', 40);
            if size(matches, 1) > 0
                points1 = valid1.Location(idx1(matches(:, 1)), :);
                points2 = valid2.Location(idx2(matches(:, 2)), :);
            end
        end
    end

    if size(points1, 1) >= 8
        try
            [~, f_inliers] = estimateFundamentalMatrix(points1, points2, ...
                'Method', 'RANSAC', 'NumTrials', 3000, 'DistanceThreshold', 1.0, 'Confidence', 99);
        catch
            f_inliers = true(size(points1, 1), 1);
        end
    else
        f_inliers = true(size(points1, 1), 1);
    end

    if isempty(points1)
        savePlaceholderImage(output_path, sprintf('No matches found for octave %d.', dom_octave));
        return;
    end

    title_str = sprintf('F-inlier correspondences — Octave %d (%d matches)', dom_octave, size(points1, 1));
    saveBestMatchFigure(I1_rgb, I2_rgb, points1, points2, f_inliers, output_path, title_str);
end

function saveFigure(fig, output_path)
    % exportgraphics gives cleaner report images when available; saveas is a
    % fallback for older MATLAB installations.
    drawnow;
    try
        exportgraphics(fig, output_path, 'Resolution', 180);
    catch
        saveas(fig, output_path);
    end
end

function cleanAxesForExport(ax)
    % Hide MATLAB's interactive axis toolbar so exported report figures look clean.
    try
        disableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Toolbar.Visible = 'off';
    catch
    end
end
