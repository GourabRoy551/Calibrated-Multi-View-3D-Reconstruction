clear all; close all; clc;

addpath(genpath('./lib'));

% Keep Section 3 figures, matrices, and report values in one folder so the
% final report can cite a clean set of reconstruction outputs.
section_dir = fullfile('results', 'section_3');
if ~exist(section_dir, 'dir')
    mkdir(section_dir);
end

fprintf('======================================================\n');
fprintf('SECTION 3: 3D RECONSTRUCTION\n');
fprintf('======================================================\n\n');

section1_path = fullfile('results', 'section_1', 'A_screen.mat');
section1_metrics_path = fullfile('results', 'section_1', 'section1_metrics.mat');
section2_path = fullfile('results', 'section_2', 'section2_metrics.mat');
scene_dir = fullfile('images', 'scene');
max_image_width = 1024;

% Section 3 depends on the fixed-camera calibration from Section 1 and the
% matching decision from Section 2.
if ~exist(section1_path, 'file')
    error('Missing Section 1 output: %s', section1_path);
end
if ~exist(section2_path, 'file')
    error('Missing Section 2 output: %s', section2_path);
end

S1 = load(section1_path, 'A');
S2 = load(section2_path, 'section2');
A_original = S1.A;
section2 = S2.section2;
calibration_size = [nan, nan];
if exist(section1_metrics_path, 'file')
    % The original calibration image size is needed when checking whether an
    % intrinsic matrix must be rotated or only scaled for the scene images.
    S1_metrics = load(section1_metrics_path, 'screen');
    calibration_size = [S1_metrics.screen.image_width, S1_metrics.screen.image_height];
end

scene_files = listImageFiles(scene_dir);
if numel(scene_files) < 4
    error('Section 3 needs at least 4 scene images in %s.', scene_dir);
end

% Prefer images with the same orientation and geometry. If the scene folder
% contains only portrait images, the code simply keeps the full sorted set.
landscape_idx = findLandscapeImages(scene_dir, scene_files);
if numel(landscape_idx) >= 4
    selected_idx = landscape_idx;
else
    selected_idx = 1:numel(scene_files);
end

[images_rgb, images_gray, scene] = readSelectedSceneImages(scene_dir, scene_files, selected_idx, ...
    max_image_width, A_original, calibration_size);

fprintf('Using %d scene views for Section 3 reconstruction.\n', numel(images_rgb));
fprintf('Selected images: %s\n\n', strjoin(scene.image_names, ', '));

% Main reconstruction pipeline: detect SIFT points, connect them into
% multi-view tracks, choose an initial pair, reconstruct projectively, then
% upgrade the result to a Euclidean reconstruction using the calibrated K.
features = detectSceneFeatures(images_gray, images_rgb, scene.image_names, section_dir);
tracks = buildReferenceTracks(features, scene);
if tracks.npoints < 12
    error('Only %d usable tracks were found. Section 3 needs more consistent matches.', tracks.npoints);
end

save(fullfile(section_dir, 'n_view_tracks.mat'), 'tracks', 'features', 'scene');

% The first two-camera reconstruction is anchored to the pair with the
% strongest track support, with the Section 2 best pair preferred when usable.
[initial_pair, tracks] = chooseInitialPair(tracks, scene, section2);
fprintf('Initial reconstruction pair: %s vs %s with %d tracks.\n', ...
    scene.image_names{initial_pair.i}, scene.image_names{initial_pair.j}, initial_pair.ntracks);

saveInitialPairFigure(images_rgb{initial_pair.i}, images_rgb{initial_pair.j}, tracks, initial_pair, ...
    fullfile(section_dir, 'initial_pair_matches.png'));

[initial, tracks] = computeInitialProjectiveReconstruction(tracks, initial_pair);
writeMatrixFile(fullfile(section_dir, 'initial_F.txt'), initial.F, 'Initial fundamental matrix');
saveReprojectionHistogram(initial.errors, fullfile(section_dir, 'initial_reprojection_hist.png'), ...
    sprintf('Initial 2-camera reprojection error (mean %.3f px)', initial.mean_error));

% Add the remaining views by estimating camera matrices from already
% triangulated 3D points and their observed 2D positions.
[resection, tracks] = resectionRemainingCameras(tracks, initial, initial_pair);
saveReprojectionHistogram(resection.errors, fullfile(section_dir, 'resection_reprojection_hist.png'), ...
    sprintf('Post-resection reprojection error (mean %.3f px)', resection.mean_error));

% Bundle adjustment refines the projective solution when the supplied library
% function succeeds. A fallback keeps the pipeline reportable if BA fails.
ba = runProjectiveBAWithFallback(tracks, resection);
saveReprojectionHistogram(ba.errors, fullfile(section_dir, 'ba_reprojection_hist.png'), ...
    sprintf('Post-BA reprojection error (mean %.3f px)', ba.mean_error));

% Recomputing F from the recovered projection matrices is a consistency check
% between the algebraic two-view result and the projective camera matrices.
F_from_P = fundamentalFromProjectionMatrices(ba.P(:, :, initial_pair.i), ba.P(:, :, initial_pair.j));
F_from_P = normalizeMatrix(F_from_P);
writeMatrixFile(fullfile(section_dir, 'F_from_P.txt'), F_from_P, 'Fundamental matrix from projective P matrices');
f_comparison = normalizedMatrixDifference(initial.F, F_from_P);

% The essential matrix gives the metric/Euclidean interpretation once the
% calibrated intrinsic matrix has been scaled to the processed image size.
[essential, A_used, intrinsic_selection] = computeEuclideanReconstruction(tracks, initial_pair, F_from_P, scene);
scene.A_used = A_used;
scene.intrinsic_selection = intrinsic_selection;
writeMatrixFile(fullfile(section_dir, 'euclidean_intrinsic_matrix.txt'), A_used, ...
    sprintf('Intrinsic matrix used for Euclidean reconstruction (%s)', intrinsic_selection.name));
writeMatrixFile(fullfile(section_dir, 'essential_matrix.txt'), essential.E, 'Essential matrix E');

euclidean = resectionEuclideanCameras(tracks, initial_pair, essential, A_used);
saveReprojectionHistogram(euclidean.errors, fullfile(section_dir, 'euclidean_reprojection_hist.png'), ...
    sprintf('Euclidean all-camera reprojection error (mean %.3f px)', euclidean.mean_error));

% Save both diagnostic and report-friendly views of the final colored point
% cloud.
cloud = saveCloudFigures(euclidean, images_rgb, tracks, initial_pair, section_dir);

section3 = struct();
section3.scene = scene;
section3.features = features;
section3.tracks = tracks;
section3.initial_pair = initial_pair;
section3.initial = initial;
section3.resection = resection;
section3.ba = ba;
section3.F_from_P = F_from_P;
section3.F_comparison = f_comparison;
section3.essential = essential;
section3.euclidean = euclidean;
section3.cloud = cloud;

save(fullfile(section_dir, 'section3_metrics.mat'), 'section3');
writeReportValues(fullfile(section_dir, 'section3_report_values.txt'), section3);

fprintf('\n>>> Section 3 coding outputs complete. <<<\n');
fprintf('Saved reconstruction values and figures to %s\n', section_dir);

function files = listImageFiles(folder_path)
    % Collect common image formats and sort by name for repeatable processing.
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

function idx = findLandscapeImages(scene_dir, scene_files)
    % Return indices of images that are wider than tall. This is useful when a
    % scene folder contains mixed captures, because reconstruction works best
    % when all views share the same image orientation.
    idx = [];
    for i = 1:numel(scene_files)
        info = imfinfo(fullfile(scene_dir, scene_files(i).name));
        if info.Width >= info.Height
            idx(end + 1) = i; %#ok<AGROW>
        end
    end
end

function [images_rgb, images_gray, scene] = readSelectedSceneImages(scene_dir, scene_files, selected_idx, max_width, A_original, calibration_size)
    % Read the selected scene images, resize large images for speed, and keep
    % the scale factors so the intrinsic matrix can be adjusted correctly.
    n = numel(selected_idx);
    images_rgb = cell(1, n);
    images_gray = cell(1, n);
    image_files = cell(1, n);
    image_names = cell(1, n);
    original_sizes = zeros(n, 2);
    resized_sizes = zeros(n, 2);
    scale_factors = ones(n, 1);

    for k = 1:n
        file_idx = selected_idx(k);
        image_files{k} = fullfile(scene_dir, scene_files(file_idx).name);
        image_names{k} = scene_files(file_idx).name;
        I = imread(image_files{k});
        if size(I, 3) == 1
            I = repmat(I, [1 1 3]);
        end
        original_sizes(k, :) = [size(I, 2), size(I, 1)];
        scale = 1;
        if size(I, 2) > max_width
            % LabFinal Note 2 requires scaling the first two rows of K by the
            % same factor used to resize the image.
            scale = max_width / size(I, 2);
            I = imresize(I, scale);
        end
        resized_sizes(k, :) = [size(I, 2), size(I, 1)];
        scale_factors(k) = scale;
        images_rgb{k} = I;
        images_gray{k} = rgb2gray(I);
    end

    [A_candidates, A_candidate_names] = buildIntrinsicCandidates(A_original, calibration_size, ...
        original_sizes(1, :), scale_factors(1));

    scene = struct();
    scene.original_indices = selected_idx;
    scene.image_files = image_files;
    scene.image_names = image_names;
    scene.original_sizes = original_sizes;
    scene.resized_sizes = resized_sizes;
    scene.scale_factors = scale_factors;
    scene.A_original = A_original;
    scene.A_candidates = A_candidates;
    scene.A_candidate_names = A_candidate_names;
    scene.A_used = A_candidates(:, :, 1);
    scene.max_image_width = max_width;
end

function [A_candidates, candidate_names] = buildIntrinsicCandidates(A_original, calibration_size, image_size, scale)
    % Test a direct scaled calibration first. Rotation candidates are added
    % only if the calibration size suggests the scene orientation differs.
    direct = scaleIntrinsics(A_original, scale);
    A_candidates = direct;
    candidate_names = {'direct scaled portrait calibration'};

    if all(isfinite(calibration_size)) && calibration_size(1) ~= image_size(1) && calibration_size(2) ~= image_size(2)
        calib_width = calibration_size(1);
        calib_height = calibration_size(2);
        clockwise_rotation = [0, -1, calib_height + 1; 1, 0, 0; 0, 0, 1];
        counterclockwise_rotation = [0, 1, 0; -1, 0, calib_width + 1; 0, 0, 1];

        A_candidates(:, :, 2) = scaleIntrinsics(clockwise_rotation * A_original, scale);
        candidate_names{2} = 'clockwise-rotated and scaled calibration';
        A_candidates(:, :, 3) = scaleIntrinsics(counterclockwise_rotation * A_original, scale);
        candidate_names{3} = 'counterclockwise-rotated and scaled calibration';
    end
end

function A_scaled = scaleIntrinsics(A, scale)
    % Scale focal lengths, skew, and principal point, but keep K(3,3) equal to
    % one as required by the intrinsic-matrix convention.
    A_scaled = A;
    A_scaled(1:2, :) = scale * A_scaled(1:2, :);
end

function features = detectSceneFeatures(images_gray, images_rgb, image_names, section_dir)
    % Detect SIFT features in each view and save a keypoint figure for the
    % report. The strongest points are retained to keep matching manageable.
    ncam = numel(images_gray);
    frames = cell(1, ncam);
    descriptors = cell(1, ncam);
    scales = cell(1, ncam);
    keypoint_counts = zeros(1, ncam);
    figure_paths = cell(1, ncam);

    for k = 1:ncam
        points = detectSIFTFeatures(images_gray{k});
        points = points.selectStrongest(min(2000, points.Count));
        [desc, valid_points] = extractFeatures(images_gray{k}, points);
        frames{k} = valid_points.Location';
        descriptors{k} = desc;
        scales{k} = valid_points.Scale;
        keypoint_counts(k) = size(frames{k}, 2);

        fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
        imshow(images_rgb{k});
        hold on;
        plot(valid_points.selectStrongest(min(300, valid_points.Count)));
        title(sprintf('Detected SIFT keypoints: %s (%d)', image_names{k}, keypoint_counts(k)), 'Interpreter', 'none');
        cleanAxesForExport(gca);
        figure_paths{k} = fullfile(section_dir, sprintf('keypoints_view_%02d.png', k));
        saveFigure(fig, figure_paths{k});
        close(fig);
    end

    features = struct();
    features.frames = frames;
    features.descriptors = descriptors;
    features.scales = scales;
    features.keypoint_counts = keypoint_counts;
    features.figure_paths = figure_paths;
    features.detector = 'MATLAB SIFT';
end

function tracks = buildReferenceTracks(features, scene)
    % Build simple N-view tracks by matching every view back to one reference
    % view. This keeps track identities consistent across cameras.
    ncam = numel(features.frames);
    ref = chooseReferenceView(features);
    ref_count = size(features.frames{ref}, 2);

    q = nan(3, ref_count, ncam);
    feature_indices = zeros(ref_count, ncam);
    q(1:2, :, ref) = features.frames{ref};
    q(3, :, ref) = 1;
    feature_indices(:, ref) = (1:ref_count)';
    raw_match_counts = zeros(1, ncam);
    geometric_inlier_counts = zeros(1, ncam);

    for k = 1:ncam
        if k == ref
            continue;
        end
        pairs = matchFeatures(features.descriptors{ref}, features.descriptors{k}, ...
            'Unique', true, 'MaxRatio', 0.75, 'MatchThreshold', 40);
        raw_match_counts(k) = size(pairs, 1);

        % A fundamental-matrix check removes descriptor matches that are not
        % geometrically plausible between the two views.
        pairs = filterPairMatchesGeometrically(features.frames{ref}, features.frames{k}, pairs);
        geometric_inlier_counts(k) = size(pairs, 1);
        for m = 1:size(pairs, 1)
            ref_idx = pairs(m, 1);
            other_idx = pairs(m, 2);
            q(1:2, ref_idx, k) = features.frames{k}(:, other_idx);
            q(3, ref_idx, k) = 1;
            feature_indices(ref_idx, k) = other_idx;
        end
    end

    vp = squeeze(isfinite(q(1, :, :)));
    if isvector(vp)
        vp = vp(:)';
    end
    visible_counts = sum(vp, 2);
    keep = visible_counts >= 2;

    q = q(:, keep, :);
    vp = vp(keep, :);
    feature_indices = feature_indices(keep, :);
    visible_counts = visible_counts(keep);

    tracks = struct();
    tracks.q = q;
    tracks.vp = vp;
    tracks.feature_indices = feature_indices;
    tracks.visible_counts = visible_counts;
    tracks.npoints = size(q, 2);
    tracks.ncam = ncam;
    tracks.reference_view = ref;
    tracks.image_names = scene.image_names;
    tracks.raw_match_counts = raw_match_counts;
    tracks.geometric_inlier_counts = geometric_inlier_counts;
end

function ref = chooseReferenceView(features)
    % The middle image normally has overlap with both sides of the sequence,
    % making it a good anchor for N-view tracks.
    ncam = numel(features.frames);
    mid = ceil(ncam / 2);
    ref = mid;
end

function pairs = filterPairMatchesGeometrically(ref_frames, other_frames, pairs)
    % RANSAC on F rejects matches that do not satisfy epipolar geometry.
    if size(pairs, 1) < 8
        return;
    end

    pts_ref = ref_frames(:, pairs(:, 1))';
    pts_other = other_frames(:, pairs(:, 2))';
    try
        [~, inliers] = estimateFundamentalMatrix(pts_ref, pts_other, ...
            'Method', 'RANSAC', 'NumTrials', 3000, 'DistanceThreshold', 1.5, 'Confidence', 99);
        if nnz(inliers) >= 8
            pairs = pairs(inliers, :);
        end
    catch
        % Keep descriptor matches if MATLAB cannot estimate F for this pair.
    end
end

function [initial_pair, tracks] = chooseInitialPair(tracks, scene, section2)
    % Choose the pair with the most shared tracks, but prefer the Section 2
    % best pair when it is available in the selected Section 3 image set.
    ncam = tracks.ncam;
    ref = tracks.reference_view;
    best_j = 0;
    best_count = -inf;

    for j = 1:ncam
        if j == ref
            continue;
        end
        count = nnz(tracks.vp(:, ref) & tracks.vp(:, j));
        if count > best_count
            best_count = count;
            best_j = j;
        end
    end

    % Prefer the Section 2 best pair if both images are part of the selected Section 3 subset.
    if isfield(section2, 'best') && isfield(section2.best, 'pair_i') && isfield(section2.best, 'pair_j')
        original_i = section2.best.pair_i;
        original_j = section2.best.pair_j;
        local_i = find(scene.original_indices == original_i, 1);
        local_j = find(scene.original_indices == original_j, 1);
        if ~isempty(local_i) && ~isempty(local_j)
            count = nnz(tracks.vp(:, local_i) & tracks.vp(:, local_j));
            if count >= 12
                ref = local_i;
                best_j = local_j;
                best_count = count;
            end
        end
    end

    if best_j == 0 || best_count < 8
        error('Could not find a two-view pair with enough shared tracks.');
    end

    pair_mask = tracks.vp(:, ref) & tracks.vp(:, best_j);
    keep = pair_mask;
    tracks.q = tracks.q(:, keep, :);
    tracks.vp = tracks.vp(keep, :);
    tracks.feature_indices = tracks.feature_indices(keep, :);
    tracks.visible_counts = sum(tracks.vp, 2);
    tracks.npoints = size(tracks.q, 2);

    initial_pair = struct();
    initial_pair.i = ref;
    initial_pair.j = best_j;
    initial_pair.name_i = scene.image_names{ref};
    initial_pair.name_j = scene.image_names{best_j};
    initial_pair.ntracks = tracks.npoints;
end

function saveInitialPairFigure(I1, I2, tracks, pair, output_path)
    % Save the matched points used to initialize the reconstruction.
    pts1 = squeeze(tracks.q(1:2, :, pair.i))';
    pts2 = squeeze(tracks.q(1:2, :, pair.j))';
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    showMatchedFeatures(I1, I2, pts1, pts2, 'montage', 'PlotOptions', {'go', 'r+', 'y-'});
    title(sprintf('Initial reconstruction pair: %s vs %s', pair.name_i, pair.name_j), 'Interpreter', 'none');
    cleanAxesForExport(gca);
    saveFigure(fig, output_path);
    close(fig);
end

function [initial, tracks] = computeInitialProjectiveReconstruction(tracks, pair)
    % Estimate F with RANSAC, keep only inlier tracks, and triangulate the
    % first projective 3D point set from the two selected cameras.
    pts1 = squeeze(tracks.q(1:2, :, pair.i))';
    pts2 = squeeze(tracks.q(1:2, :, pair.j))';

    [F, inliers] = estimateFundamentalMatrix(pts1, pts2, ...
        'Method', 'RANSAC', 'NumTrials', 5000, 'DistanceThreshold', 1.0, 'Confidence', 99);
    if nnz(inliers) < 8
        error('Initial pair produced only %d F inliers.', nnz(inliers));
    end

    tracks.q = tracks.q(:, inliers, :);
    tracks.vp = tracks.vp(inliers, :);
    tracks.feature_indices = tracks.feature_indices(inliers, :);
    tracks.visible_counts = sum(tracks.vp, 2);
    tracks.npoints = size(tracks.q, 2);

    q2 = tracks.q(:, :, [pair.i pair.j]);
    P_pair = projectiveCamerasFromF(F);
    Q = linearTriangulateMultiview(P_pair, q2);
    [errors, mean_error] = reprojectionErrors(q2, P_pair, Q, true(size(q2, 2), 2));

    P = nan(3, 4, tracks.ncam);
    P(:, :, pair.i) = P_pair(:, :, 1);
    P(:, :, pair.j) = P_pair(:, :, 2);

    initial = struct();
    initial.F = F;
    initial.inlier_count = nnz(inliers);
    initial.P_pair = P_pair;
    initial.P = P;
    initial.Q = Q;
    initial.q_pair = q2;
    initial.errors = errors;
    initial.mean_error = mean_error;
end

function P = projectiveCamerasFromF(F)
    % Canonical projective cameras for a two-view reconstruction:
    % P1 = [I|0], P2 = [[e']x F | e'].
    F = normalizeMatrix(F);
    [~, ~, V] = svd(F');
    e2 = V(:, end);
    if abs(e2(3)) > eps
        e2 = e2 ./ e2(3);
    else
        e2 = e2 ./ norm(e2);
    end
    P = zeros(3, 4, 2);
    P(:, :, 1) = [eye(3), zeros(3, 1)];
    P(:, :, 2) = [skewMatrix(e2) * F, e2];
end

function [resection, tracks] = resectionRemainingCameras(tracks, initial, pair)
    % Estimate projection matrices for cameras not in the initial pair using
    % 2D-3D correspondences and reject large reprojection-error outliers.
    P = initial.P;
    Q = initial.Q;
    vp = tracks.vp;
    camera_mean_errors = nan(1, tracks.ncam);
    camera_inlier_counts = zeros(1, tracks.ncam);

    for k = 1:tracks.ncam
        if k == pair.i || k == pair.j
            camera_inlier_counts(k) = nnz(vp(:, k));
            continue;
        end
        idx = find(vp(:, k));
        [Pk, local_inliers, cam_mean_error] = robustResectionDLT(tracks.q(:, idx, k), Q(:, idx), 25);
        if ~isempty(Pk)
            P(:, :, k) = Pk;
            rejected_idx = idx;
            rejected_idx(local_inliers) = [];
            vp(rejected_idx, k) = false;
            camera_mean_errors(k) = cam_mean_error;
            camera_inlier_counts(k) = numel(local_inliers);
        else
            vp(idx, k) = false;
        end
    end

    valid_cam = squeeze(all(all(isfinite(P), 1), 2));
    vp(:, ~valid_cam) = false;
    tracks.vp = vp;
    tracks.visible_counts = sum(tracks.vp, 2);
    [errors, mean_error] = reprojectionErrors(tracks.q, P, Q, tracks.vp);

    resection = struct();
    resection.P = P;
    resection.Q = Q;
    resection.valid_cameras = valid_cam(:)';
    resection.camera_mean_errors = camera_mean_errors;
    resection.camera_inlier_counts = camera_inlier_counts;
    resection.errors = errors;
    resection.mean_error = mean_error;
end

function ba = runProjectiveBAWithFallback(tracks, resection)
    % Try projective bundle adjustment from the lab library. If it fails or
    % returns invalid values, keep the resection result so the rest of the
    % pipeline can still be evaluated.
    ba = struct();
    ba.used_bundle_adjustment = false;
    valid_cam = resection.valid_cameras & squeeze(all(all(isfinite(resection.P), 1), 2))';
    try
        [P_BA_valid, Q_BA, q_BA] = BAProjectiveCalib(tracks.q(:, :, valid_cam), ...
            resection.P(:, :, valid_cam), resection.Q, tracks.vp(:, valid_cam));
        if all(isfinite(P_BA_valid(:))) && all(isfinite(Q_BA(:)))
            P_BA = nan(size(resection.P));
            P_BA(:, :, valid_cam) = P_BA_valid;
            [errors, mean_error] = reprojectionErrors(tracks.q(:, :, valid_cam), ...
                P_BA_valid, Q_BA, tracks.vp(:, valid_cam));
            ba.P = P_BA;
            ba.Q = Q_BA;
            ba.q_BA = q_BA;
            ba.valid_cameras = valid_cam;
            ba.errors = errors;
            ba.mean_error = mean_error;
            ba.used_bundle_adjustment = true;
            ba.status = 'BAProjectiveCalib completed successfully';
            return;
        end
    catch ME
        ba.status = sprintf('BAProjectiveCalib failed; using resection result as fallback. Reason: %s', ME.message);
    end

    ba.P = resection.P;
    ba.Q = resection.Q;
    ba.q_BA = [];
    ba.valid_cameras = resection.valid_cameras;
    ba.errors = resection.errors;
    ba.mean_error = resection.mean_error;
    if ~isfield(ba, 'status')
        ba.status = 'BAProjectiveCalib returned invalid values; using resection result as fallback';
    end
end

function F = fundamentalFromProjectionMatrices(P1, P2)
    % Recover F from two projection matrices using the first camera center and
    % the epipole in the second image.
    C1 = null(P1);
    C1 = C1 ./ C1(end);
    e2 = P2 * C1;
    F = skewMatrix(e2) * P2 * pinv(P1);
end

function diff_value = normalizedMatrixDifference(A, B)
    % F and E are defined only up to scale and sign, so compare both sign
    % possibilities after Frobenius normalization.
    A = normalizeMatrix(A);
    B = normalizeMatrix(B);
    diff_value = min(norm(A - B, 'fro'), norm(A + B, 'fro'));
end

function [essential, A_used, intrinsic_selection] = computeEuclideanReconstruction(tracks, pair, F, scene)
    % Try each reasonable intrinsic-matrix candidate and choose the one with
    % low reprojection error and the strongest positive-depth consistency.
    candidates = scene.A_candidates;
    candidate_names = scene.A_candidate_names;
    q_pair = tracks.q(:, :, [pair.i pair.j]);
    expected_positive = 2 * size(q_pair, 2);

    best_score = inf;
    best_idx = 1;
    candidate_results = repmat(struct('mean_error', inf, 'positive_count', 0, 'name', ''), 1, size(candidates, 3));
    for c = 1:size(candidates, 3)
        candidate = computeEuclideanCandidate(tracks, pair, F, candidates(:, :, c));
        [~, pair_mean_error] = reprojectionErrors(q_pair, candidate.P_pair, candidate.Q, true(size(q_pair, 2), 2));
        candidate.pair_reprojection_error = pair_mean_error;

        positive_penalty = max(0, expected_positive - candidate.cheirality_positive_count);
        score = pair_mean_error + positive_penalty;
        candidate_results(c).mean_error = pair_mean_error;
        candidate_results(c).positive_count = candidate.cheirality_positive_count;
        candidate_results(c).name = candidate_names{c};
        if score < best_score
            best_score = score;
            best_idx = c;
            essential = candidate;
        end
    end

    A_used = candidates(:, :, best_idx);
    intrinsic_selection = struct();
    intrinsic_selection.name = candidate_names{best_idx};
    intrinsic_selection.index = best_idx;
    intrinsic_selection.candidates = candidate_results;
end

function essential = computeEuclideanCandidate(tracks, pair, F, A)
    % Convert F to E with the calibrated intrinsics, enforce the essential
    % matrix singular-value structure, and test the possible camera poses.
    E = A' * F * A;
    E = enforceEssentialSingularValues(E);
    [R_candidates, T] = factorize_E(E);

    q_pair = tracks.q(:, :, [pair.i pair.j]);
    expected_positive = 2 * size(q_pair, 2);
    best_score = inf;
    best = struct();
    candidate_id = 0;
    for r_idx = 1:2
        for sign_t = [-1, 1]
            R = R_candidates(:, :, r_idx);
            signed_T = sign_t * T(:);
            pose_forms = buildPoseForms(R, signed_T);
            for form_idx = 1:numel(pose_forms)
                candidate_id = candidate_id + 1;
                R_pose = pose_forms(form_idx).R;
                t_pose = pose_forms(form_idx).t;

                % Cheirality selects the physically valid pose: reconstructed
                % points should lie in front of both cameras.
                P = zeros(3, 4, 2);
                P(:, :, 1) = A * [eye(3), zeros(3, 1)];
                P(:, :, 2) = A * [R_pose, t_pose];
                Q = linearTriangulateMultiview(P, q_pair);
                positive = countPositiveDepth(Q, P);
                [~, candidate_error] = reprojectionErrors(q_pair, P, Q, true(size(q_pair, 2), 2));
                positive_penalty = max(0, expected_positive - positive);
                score = candidate_error + positive_penalty;
                if score < best_score
                    best_score = score;
                    best.R = R_pose;
                    best.t = t_pose;
                    best.P_pair = P;
                    best.Q = Q;
                    best.candidate_id = candidate_id;
                    best.pose_form = pose_forms(form_idx).name;
                    best.cheirality_positive_count = positive;
                    best.pair_reprojection_error = candidate_error;
                end
            end
        end
    end

    essential = struct();
    essential.E = E;
    essential.R = best.R;
    essential.t = best.t;
    essential.P_pair = best.P_pair;
    essential.Q = best.Q;
    essential.cheirality_positive_count = best.cheirality_positive_count;
    essential.cheirality_candidate_id = best.candidate_id;
    essential.pose_form = best.pose_form;
    essential.pair_reprojection_error = best.pair_reprojection_error;
end

function pose_forms = buildPoseForms(R, T)
    % Different libraries use slightly different translation conventions, so
    % test the plausible forms instead of assuming one sign convention.
    pose_forms = repmat(struct('R', eye(3), 't', zeros(3, 1), 'name', ''), 1, 4);
    pose_forms(1).R = R;
    pose_forms(1).t = T;
    pose_forms(1).name = 'P2 = K [R | T]';
    pose_forms(2).R = R;
    pose_forms(2).t = -R * T;
    pose_forms(2).name = 'P2 = K [R | -R*T]';
    pose_forms(3).R = R';
    pose_forms(3).t = T;
    pose_forms(3).name = 'P2 = K [R'' | T]';
    pose_forms(4).R = R';
    pose_forms(4).t = -R' * T;
    pose_forms(4).name = 'P2 = K [R'' | -R''*T]';
end

function E = enforceEssentialSingularValues(E)
    % A valid essential matrix has two equal non-zero singular values and one
    % zero singular value.
    [U, S, V] = svd(E);
    s = (S(1, 1) + S(2, 2)) / 2;
    E = U * diag([s s 0]) * V';
    E = normalizeMatrix(E);
end

function euclidean = resectionEuclideanCameras(tracks, pair, essential, A)
    % Start from the selected Euclidean two-camera solution and resection the
    % remaining cameras into the same metric coordinate frame.
    P = nan(3, 4, tracks.ncam);
    P(:, :, pair.i) = essential.P_pair(:, :, 1);
    P(:, :, pair.j) = essential.P_pair(:, :, 2);
    Q = essential.Q;
    vp = tracks.vp;
    camera_mean_errors = nan(1, tracks.ncam);
    camera_inlier_counts = zeros(1, tracks.ncam);

    for k = 1:tracks.ncam
        if k == pair.i || k == pair.j
            camera_inlier_counts(k) = nnz(vp(:, k));
            continue;
        end
        idx = find(vp(:, k));
        [Pk, local_inliers, cam_mean_error] = robustResectionDLT(tracks.q(:, idx, k), Q(:, idx), 25);
        if ~isempty(Pk)
            P(:, :, k) = Pk;
            rejected_idx = idx;
            rejected_idx(local_inliers) = [];
            vp(rejected_idx, k) = false;
            camera_mean_errors(k) = cam_mean_error;
            camera_inlier_counts(k) = numel(local_inliers);
        else
            vp(idx, k) = false;
        end
    end

    valid_cam = squeeze(all(all(isfinite(P), 1), 2));
    vp(:, ~valid_cam) = false;
    [errors, mean_error] = reprojectionErrors(tracks.q, P, Q, vp);

    centers = cameraCenters(P);
    euclidean = struct();
    euclidean.P = P;
    euclidean.Q = Q;
    euclidean.valid_cameras = valid_cam(:)';
    euclidean.visibility = vp;
    euclidean.camera_mean_errors = camera_mean_errors;
    euclidean.camera_inlier_counts = camera_inlier_counts;
    euclidean.camera_centers = centers;
    euclidean.errors = errors;
    euclidean.mean_error = mean_error;
    euclidean.A = A;
end

function [P_best, inlier_idx, mean_error] = robustResectionDLT(q_cam, Q_cam, max_mean_error)
    % A small robust loop around DLT: estimate a camera, remove high-error
    % correspondences, and keep the best projection matrix found.
    P_best = [];
    inlier_idx = [];
    mean_error = inf;
    npoints = size(q_cam, 2);
    if npoints < 6
        return;
    end

    working_idx = 1:npoints;
    for iter = 1:4
        if numel(working_idx) < 6
            break;
        end
        try
            P_candidate = PDLT_NA(q_cam(:, working_idx), Q_cam(:, working_idx));
        catch
            break;
        end

        all_errors = singleCameraReprojectionErrors(q_cam, P_candidate, Q_cam);
        finite_errors = all_errors(isfinite(all_errors));
        if isempty(finite_errors)
            break;
        end

        candidate_mean = mean(all_errors(working_idx), 'omitnan');
        if candidate_mean < mean_error
            P_best = P_candidate;
            inlier_idx = working_idx;
            mean_error = candidate_mean;
        end

        median_error = median(finite_errors);
        threshold = min(20, max(4, 2.5 * median_error));
        next_idx = find(all_errors <= threshold);
        if numel(next_idx) < 6
            [~, order] = sort(all_errors, 'ascend', 'MissingPlacement', 'last');
            next_idx = order(1:min(max(6, min(10, npoints)), npoints));
        end

        if isequal(sort(next_idx(:)), sort(working_idx(:))) || iter == 4
            break;
        end
        working_idx = sort(next_idx(:))';
    end

    if isempty(P_best) || numel(inlier_idx) < 6 || mean_error > max_mean_error
        P_best = [];
        inlier_idx = [];
        mean_error = inf;
    end
end

function errors = singleCameraReprojectionErrors(q_cam, P, Q)
    % Compute pixel reprojection errors for one camera and one 3D point set.
    proj = P * Q;
    proj = proj ./ proj(3, :);
    errors = sqrt(sum((proj(1:2, :) - q_cam(1:2, :)).^2, 1));
end

function cloud = saveCloudFigures(euclidean, images_rgb, tracks, pair, section_dir)
    % Use the reference image colors for the reconstructed points and save
    % multiple views so the report can show the 3D structure clearly.
    valid_points = finitePointMask(euclidean.Q);
    Q = unhom(euclidean.Q(:, valid_points));
    q_ref = tracks.q(:, valid_points, pair.i);
    colors = samplePointColors(q_ref, images_rgb{pair.i});
    centers = euclidean.camera_centers;

    cloud = struct();
    cloud.with_cameras_fig = fullfile(section_dir, 'cloud_with_cameras.fig');
    cloud.scene_only_fig = fullfile(section_dir, 'cloud_scene_only.fig');
    cloud.with_cameras_view_1 = fullfile(section_dir, 'cloud_with_cameras_view_1.png');
    cloud.with_cameras_view_2 = fullfile(section_dir, 'cloud_with_cameras_view_2.png');
    cloud.scene_only_view_1 = fullfile(section_dir, 'cloud_scene_only_view_1.png');
    cloud.scene_only_view_2 = fullfile(section_dir, 'cloud_scene_only_view_2.png');
    cloud.colored_cloud = fullfile(section_dir, 'colored_cloud.png');

    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    scatter3(Q(1, :), Q(2, :), Q(3, :), 16, colors, 'filled');
    hold on;
    plotCameraCenters(centers);
    grid on; axis equal; xlabel('X'); ylabel('Y'); zlabel('Z');
    title('Euclidean point cloud with camera centers');
    view(35, 25);
    savefig(fig, cloud.with_cameras_fig);
    saveFigure(fig, cloud.with_cameras_view_1);
    view(-45, 20);
    saveFigure(fig, cloud.with_cameras_view_2);
    close(fig);

    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    scatter3(Q(1, :), Q(2, :), Q(3, :), 16, colors, 'filled');
    grid on; axis equal; xlabel('X'); ylabel('Y'); zlabel('Z');
    title('Euclidean scene point cloud');
    view(35, 25);
    savefig(fig, cloud.scene_only_fig);
    saveFigure(fig, cloud.scene_only_view_1);
    view(-45, 20);
    saveFigure(fig, cloud.scene_only_view_2);
    close(fig);

    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    scatter3(Q(1, :), Q(2, :), Q(3, :), 18, colors, 'filled');
    grid on; axis equal; xlabel('X'); ylabel('Y'); zlabel('Z');
    title('Colored Euclidean point cloud');
    view(35, 25);
    saveFigure(fig, cloud.colored_cloud);
    close(fig);
end

function valid = finitePointMask(Q)
    % Homogeneous points with finite coordinates and non-zero scale can be
    % safely converted to Euclidean 3D coordinates.
    valid = all(isfinite(Q), 1) & abs(Q(4, :)) > eps;
end

function colors = samplePointColors(q_ref, I)
    % Color each 3D point using the pixel where its reference-view observation
    % appears. This makes the sparse cloud easier to interpret visually.
    n = size(q_ref, 2);
    colors = zeros(n, 3);
    for i = 1:n
        x = round(q_ref(1, i));
        y = round(q_ref(2, i));
        x = min(max(x, 1), size(I, 2));
        y = min(max(y, 1), size(I, 1));
        colors(i, :) = double(reshape(I(y, x, :), [1 3])) / 255;
    end
end

function plotCameraCenters(centers)
    % Mark camera centers in red so the report figures show both the scene and
    % the estimated camera positions.
    valid = all(isfinite(centers), 1);
    C = centers(:, valid);
    scatter3(C(1, :), C(2, :), C(3, :), 80, 'r', '^', 'filled');
    for i = 1:size(C, 2)
        text(C(1, i), C(2, i), C(3, i), sprintf(' C%d', i), 'Color', 'r', 'FontWeight', 'bold');
    end
end

function centers = cameraCenters(P)
    % The camera center is the null-space vector of its projection matrix.
    ncam = size(P, 3);
    centers = nan(3, ncam);
    for k = 1:ncam
        if all(isfinite(P(:, :, k)), 'all')
            C = null(P(:, :, k));
            C = C ./ C(end);
            centers(:, k) = C(1:3);
        end
    end
end

function Q = linearTriangulateMultiview(P, q)
    % Linear triangulation from all available views of each track.
    npoints = size(q, 2);
    ncam = size(q, 3);
    Q = nan(4, npoints);
    for i = 1:npoints
        A = [];
        for k = 1:ncam
            if all(isfinite(q(:, i, k))) && all(isfinite(P(:, :, k)), 'all')
                x = q(1, i, k);
                y = q(2, i, k);
                Pk = P(:, :, k);
                A = [A; x * Pk(3, :) - Pk(1, :); y * Pk(3, :) - Pk(2, :)]; %#ok<AGROW>
            end
        end
        if size(A, 1) >= 4
            [~, ~, V] = svd(A, 0);
            X = V(:, end);
            Q(:, i) = X ./ X(end);
        end
    end
end

function [errors, mean_error] = reprojectionErrors(q, P, Q, vp)
    % Gather all valid per-observation reprojection errors across cameras.
    errors = [];
    ncam = size(q, 3);
    for k = 1:ncam
        if ~all(isfinite(P(:, :, k)), 'all')
            continue;
        end
        idx = find(vp(:, k)' & all(isfinite(Q), 1));
        if isempty(idx)
            continue;
        end
        proj = P(:, :, k) * Q(:, idx);
        proj = proj ./ proj(3, :);
        obs = q(1:2, idx, k);
        e = sqrt(sum((proj(1:2, :) - obs).^2, 1));
        errors = [errors, e]; %#ok<AGROW>
    end
    if isempty(errors)
        mean_error = inf;
    else
        mean_error = mean(errors);
    end
end

function saveReprojectionHistogram(errors, output_path, title_text)
    % Histograms make it easier to judge whether the mean error is dominated
    % by many small residuals or a few large outliers.
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    if isempty(errors) || all(~isfinite(errors))
        text(0.1, 0.5, 'No reprojection errors available.', 'FontSize', 14);
        axis off;
    else
        histogram(errors(isfinite(errors)), min(40, max(10, round(sqrt(numel(errors))))));
        xlabel('Reprojection error (pixels)');
        ylabel('Count');
        title(title_text);
        grid on;
    end
    cleanAxesForExport(gca);
    saveFigure(fig, output_path);
    close(fig);
end

function n = countPositiveDepth(Q, P)
    % Count positive depths across all cameras for cheirality testing.
    n = 0;
    for k = 1:size(P, 3)
        depth = P(3, :, k) * Q;
        n = n + nnz(depth > 0);
    end
end

function X = unhom(Q)
    % Convert homogeneous 4D point coordinates to 3D Euclidean coordinates.
    X = Q(1:3, :) ./ Q(4, :);
end

function M = normalizeMatrix(M)
    % Normalize matrices before comparison or saving so scale ambiguity does
    % not hide the actual geometric relationship.
    scale = norm(M, 'fro');
    if scale > 0 && isfinite(scale)
        M = M / scale;
    end
end

function S = skewMatrix(v)
    % Skew-symmetric matrix used for cross-product operations.
    v = v(:);
    S = [0, -v(3), v(2); v(3), 0, -v(1); -v(2), v(1), 0];
end

function writeMatrixFile(output_path, M, label)
    % Save matrices as plain text so they can be inspected and cited in the
    % report without opening MATLAB .mat files.
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
        for r = 1:size(M, 1)
            fprintf(fid, '  ');
            fprintf(fid, '%14.8f ', M(r, :));
            fprintf(fid, '\n');
        end
    end
end

function writeReportValues(output_path, section3)
    % This file is the single source of truth for the Section 3 report text.
    % It records the important numeric values and points to every figure.
    fid = fopen(output_path, 'w');
    if fid == -1
        error('Could not open %s for writing.', output_path);
    end
    cleanup_obj = onCleanup(@() fclose(fid));

    fprintf(fid, 'SECTION 3 REPORT VALUES\n');
    fprintf(fid, '=======================\n\n');

    fprintf(fid, '3.1 N-view input images and keypoints\n');
    fprintf(fid, '-------------------------------------\n');
    fprintf(fid, 'Detector: %s\n', section3.features.detector);
    fprintf(fid, 'Images used: %d\n', numel(section3.scene.image_names));
    fprintf(fid, 'Image files:\n');
    writeCellList(fid, section3.scene.image_names);
    fprintf(fid, 'Keypoint counts:\n');
    for i = 1:numel(section3.features.keypoint_counts)
        fprintf(fid, '- %s: %d keypoints | figure %s\n', section3.scene.image_names{i}, section3.features.keypoint_counts(i), section3.features.figure_paths{i});
    end
    fprintf(fid, 'Tracks retained: %d\n', section3.tracks.npoints);
    fprintf(fid, 'Reference view: %s\n', section3.scene.image_names{section3.tracks.reference_view});
    fprintf(fid, 'Visibility counts per track: min %d, max %d, mean %.3f\n', ...
        min(section3.tracks.visible_counts), max(section3.tracks.visible_counts), mean(section3.tracks.visible_counts));

    fprintf(fid, '\n3.2 Initial two-camera reconstruction\n');
    fprintf(fid, '-------------------------------------\n');
    fprintf(fid, 'Initial pair: %s vs %s\n', section3.initial_pair.name_i, section3.initial_pair.name_j);
    fprintf(fid, 'Pair tracks: %d\n', section3.initial_pair.ntracks);
    fprintf(fid, 'Initial F inliers after RANSAC: %d\n', section3.initial.inlier_count);
    fprintf(fid, 'Initial mean reprojection error: %.6f px\n', section3.initial.mean_error);
    fprintf(fid, 'Initial pair figure: results/section_3/initial_pair_matches.png\n');
    fprintf(fid, 'Initial F: results/section_3/initial_F.txt\n');
    fprintf(fid, 'Initial reprojection histogram: results/section_3/initial_reprojection_hist.png\n');

    fprintf(fid, '\n3.3 Resectioning and Projective Bundle Adjustment\n');
    fprintf(fid, '-------------------------------------------------\n');
    fprintf(fid, 'Post-resection mean reprojection error: %.6f px\n', section3.resection.mean_error);
    fprintf(fid, 'BA status: %s\n', section3.ba.status);
    fprintf(fid, 'Bundle adjustment used: %d\n', section3.ba.used_bundle_adjustment);
    fprintf(fid, 'Post-BA mean reprojection error: %.6f px\n', section3.ba.mean_error);
    fprintf(fid, 'Resection histogram: results/section_3/resection_reprojection_hist.png\n');
    fprintf(fid, 'BA histogram: results/section_3/ba_reprojection_hist.png\n');

    fprintf(fid, '\n3.4 Fundamental matrix from projection matrices\n');
    fprintf(fid, '-----------------------------------------------\n');
    fprintf(fid, 'F_from_P file: results/section_3/F_from_P.txt\n');
    fprintf(fid, 'Normalized difference from initial F: %.6f\n', section3.F_comparison);

    fprintf(fid, '\n3.5 Essential matrix and Euclidean factorization\n');
    fprintf(fid, '-----------------------------------------------\n');
    fprintf(fid, 'Intrinsic matrix selection: %s\n', section3.scene.intrinsic_selection.name);
    fprintf(fid, 'Intrinsic matrix file: results/section_3/euclidean_intrinsic_matrix.txt\n');
    fprintf(fid, 'Intrinsic candidate check:\n');
    for i = 1:numel(section3.scene.intrinsic_selection.candidates)
        candidate = section3.scene.intrinsic_selection.candidates(i);
        fprintf(fid, '- %s: pair reprojection %.6f px, cheirality count %d\n', ...
            candidate.name, candidate.mean_error, candidate.positive_count);
    end
    fprintf(fid, 'Essential matrix file: results/section_3/essential_matrix.txt\n');
    fprintf(fid, 'Selected-pair Euclidean reprojection error: %.6f px\n', section3.essential.pair_reprojection_error);
    fprintf(fid, 'Cheirality-positive depth count: %d\n', section3.essential.cheirality_positive_count);
    fprintf(fid, 'Chosen candidate id: %d\n', section3.essential.cheirality_candidate_id);
    fprintf(fid, 'Chosen pose convention: %s\n', section3.essential.pose_form);
    fprintf(fid, 'Translation direction t = [%.6f %.6f %.6f]^T\n', section3.essential.t(1), section3.essential.t(2), section3.essential.t(3));

    fprintf(fid, '\n3.6 Final Euclidean point cloud\n');
    fprintf(fid, '-------------------------------\n');
    fprintf(fid, 'Euclidean mean reprojection error: %.6f px\n', section3.euclidean.mean_error);
    fprintf(fid, 'Euclidean histogram: results/section_3/euclidean_reprojection_hist.png\n');
    fprintf(fid, 'Cloud with cameras view 1: %s\n', section3.cloud.with_cameras_view_1);
    fprintf(fid, 'Cloud with cameras view 2: %s\n', section3.cloud.with_cameras_view_2);
    fprintf(fid, 'Scene-only cloud view 1: %s\n', section3.cloud.scene_only_view_1);
    fprintf(fid, 'Scene-only cloud view 2: %s\n', section3.cloud.scene_only_view_2);
    fprintf(fid, 'Cloud with cameras fig: %s\n', section3.cloud.with_cameras_fig);
    fprintf(fid, 'Scene-only cloud fig: %s\n', section3.cloud.scene_only_fig);
    fprintf(fid, 'Colored cloud: %s\n', section3.cloud.colored_cloud);
end

function writeCellList(fid, values)
    % Small helper for readable image-name lists in the report-values file.
    for i = 1:numel(values)
        fprintf(fid, '- %s\n', values{i});
    end
end

function saveFigure(fig, output_path)
    % Prefer exportgraphics for consistent resolution, with saveas as a
    % compatibility fallback for older MATLAB installs.
    drawnow;
    try
        exportgraphics(fig, output_path, 'Resolution', 180);
    catch
        saveas(fig, output_path);
    end
end

function cleanAxesForExport(ax)
    % Remove interactive axes controls from saved figures.
    try
        disableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Toolbar.Visible = 'off';
    catch
    end
end
