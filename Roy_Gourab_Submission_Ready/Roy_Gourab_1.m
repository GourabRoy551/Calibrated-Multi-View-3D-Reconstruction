clear all; close all; clc;
warning('off', 'vision:calibrate:boardShouldBeAsymmetric');

addpath(genpath('./lib'));

% Keep all Section 1 outputs together so the report can be written from one
% folder without hunting through intermediate MATLAB variables.
res_root = 'results';
section_dir = fullfile(res_root, 'section_1');
if ~exist(section_dir, 'dir')
    mkdir(section_dir);
end

fprintf('======================================================\n');
fprintf('SECTION 1: CAMERA CALIBRATION\n');
fprintf('All report-ready outputs will be saved in %s\n', section_dir);
fprintf('======================================================\n\n');

% -------------------------------------------------------------------------
% Shared camera/image assumptions
% -------------------------------------------------------------------------
img_dir_screen = fullfile('images', 'calibration_screen');
img_dir_custom = fullfile('images', 'calibration_custom');

% Measured screen-checkerboard dimensions.
board_width_mm = 182.6;

% Measured custom floor-tile grid dimensions.
tile_size_mm = 330;

% -------------------------------------------------------------------------
% SECTION 1.1: DIGITAL SCREEN CALIBRATION (MATRIX A)
% -------------------------------------------------------------------------
fprintf('======================================================\n');
fprintf('STARTING PART 1.1: DIGITAL SCREEN CALIBRATION\n');
fprintf('======================================================\n');

files_screen = listImageFiles(img_dir_screen);
if isempty(files_screen)
    error('No screen calibration images found in %s.', img_dir_screen);
end

% The first calibration image defines the image resolution used later for
% principal-point and reprojection-error reporting.
first_screen = imread(fullfile(img_dir_screen, files_screen(1).name));
[img_H_screen, img_W_screen, ~] = size(first_screen);

% These arrays are preallocated to the number of available files and trimmed
% after invalid checkerboard detections are skipped.
H_screen = cell(1, length(files_screen));
img_pts_screen = cell(1, length(files_screen));
screen_image_files = cell(1, length(files_screen));
screen_image_names = cell(1, length(files_screen));
screen_valid_count = 0;
screen_board_size = [];
screen_square_size_mm = [];
real_pts_screen = [];

for i = 1:length(files_screen)
    img_path = fullfile(img_dir_screen, files_screen(i).name);
    I = imread(img_path);

    % MATLAB checkerboard detection works on grayscale images.
    if size(I, 3) == 3
        I_gray = rgb2gray(I);
    else
        I_gray = I;
    end

    % Image points come from the digital checkerboard corners detected by
    % MATLAB; the corresponding world points are created from the measured
    % screen checkerboard width.
    [img_pts, board_size] = detectCheckerboardPoints(I_gray);
    if isempty(img_pts)
        fprintf('Skipping %s: checkerboard was not detected.\n', files_screen(i).name);
        continue;
    end

    % Use the first valid image to establish the checkerboard layout. All
    % later images must match this layout so every homography uses the same
    % point ordering.
    if isempty(screen_board_size)
        screen_board_size = board_size;
        screen_square_size_mm = board_width_mm / screen_board_size(1);
        real_pts_screen = generateCheckerboardPoints(screen_board_size, screen_square_size_mm)';
    end

    if ~isequal(board_size, screen_board_size)
        fprintf('Skipping %s: detected board size differs from the first valid image.\n', files_screen(i).name);
        continue;
    end

    img_pts_2xn = img_pts';
    if size(img_pts_2xn, 2) ~= size(real_pts_screen, 2)
        fprintf('Skipping %s: detected point count does not match generated world points.\n', files_screen(i).name);
        continue;
    end

    % Each valid calibration image contributes one refined planar homography
    % to Zhang-style intrinsic calibration.
    H_init = homography_solve_vmmc(real_pts_screen, img_pts_2xn);
    [H_ref, ~] = homography_refine_vmmc(real_pts_screen, img_pts_2xn, H_init);

    screen_valid_count = screen_valid_count + 1;
    H_screen{screen_valid_count} = H_ref;
    img_pts_screen{screen_valid_count} = img_pts_2xn;
    screen_image_files{screen_valid_count} = img_path;
    screen_image_names{screen_valid_count} = files_screen(i).name;
end

H_screen = H_screen(1:screen_valid_count);
img_pts_screen = img_pts_screen(1:screen_valid_count);
screen_image_files = screen_image_files(1:screen_valid_count);
screen_image_names = screen_image_names(1:screen_valid_count);
if screen_valid_count < 5
    error('Only %d valid screen calibration images were detected. Section 1 requires at least 5.', screen_valid_count);
end

% Save the calibration-image montage before solving the final matrix so the
% same images are documented in the report.
saveMontage(screen_image_files, fullfile(section_dir, 'montage_screen.png'));

A = internal_parameters_solve_vmmc(H_screen);
assertRealIntrinsicMatrix(A, 'A from screen calibration');
save(fullfile(section_dir, 'A_screen.mat'), 'A');

% Report metrics summarize the three checks required in the lab statement:
% square pixels, principal-point location, and image-axis orthogonality.
screen_metrics = computeIntrinsicMetrics(A, img_W_screen, img_H_screen);
[screen_reproj_mean, screen_reproj_errors, screen_reproj_pts] = computeReprojectionCheck( ...
    A, H_screen{1}, real_pts_screen, img_pts_screen{1}, screen_image_files{1}, ...
    fullfile(section_dir, 'reprojection_screen.png'), 'Screen calibration reprojection');

fprintf('\n--- Matrix A (Screen) ---\n');
disp(A);
printMetrics('Screen calibration', screen_metrics, screen_reproj_mean);

% -------------------------------------------------------------------------
% SECTION 1.2: CUSTOM PATTERN CALIBRATION (MATRIX A_PRIME)
% -------------------------------------------------------------------------
fprintf('\n======================================================\n');
fprintf('STARTING PART 1.2: CUSTOM FLOOR-TILE CALIBRATION\n');
fprintf('======================================================\n');

files_custom = listImageFiles(img_dir_custom);
if isempty(files_custom)
    error('No custom calibration images found in %s.', img_dir_custom);
end

first_custom = imread(fullfile(img_dir_custom, files_custom(1).name));
[img_H_custom, img_W_custom, ~] = size(first_custom);

% The custom calibration uses all available floor-tile images. The file
% names are saved because the clicked points must correspond to the same
% image order when cached data is reused.
custom_image_files = cell(1, length(files_custom));
custom_image_names = cell(1, length(files_custom));
for i = 1:length(files_custom)
    custom_image_files{i} = fullfile(img_dir_custom, files_custom(i).name);
    custom_image_names{i} = files_custom(i).name;
end

saveMontage(custom_image_files, fullfile(section_dir, 'montage_custom.png'));

% 3x3 grid of measured floor-tile corners. Click these points row by row,
% left to right, top to bottom, in every image.
real_pts_custom = zeros(2, 9);
idx = 1;
for y = 0:tile_size_mm:(tile_size_mm * 2)
    for x = 0:tile_size_mm:(tile_size_mm * 2)
        real_pts_custom(:, idx) = [x; y];
        idx = idx + 1;
    end
end

custom_points_cache = fullfile(section_dir, 'custom_clicked_points.mat');
img_pts_custom = {};
use_cached_custom_points = false;
if exist(custom_points_cache, 'file')
    % Reuse manual clicks only when the image list is unchanged. This avoids
    % accidentally applying old clicks to a different calibration sequence.
    cache = load(custom_points_cache, 'img_pts_custom', 'custom_image_names');
    if isfield(cache, 'img_pts_custom') && isfield(cache, 'custom_image_names') && isequal(cache.custom_image_names, custom_image_names)
        img_pts_custom = cache.img_pts_custom;
        use_cached_custom_points = true;
        fprintf('Loaded cached custom clicked points from %s.\n', custom_points_cache);
    end
end

if ~use_cached_custom_points
    img_pts_custom = cell(1, length(files_custom));

    fprintf('\nManual custom point selection is required.\n');
    fprintf('Click the 3x3 grid row by row: top-left to top-right, then middle row, then bottom row.\n');
    fprintf('Use LEFT click for the first 8 points and RIGHT click for the 9th point.\n\n');

    for i = 1:length(files_custom)
        I = imread(custom_image_files{i});
        fprintf('Image %d/%d: %s\n', i, length(files_custom), files_custom(i).name);

        % Manual selection is used because the floor-tile pattern is not a
        % standard checkerboard that MATLAB can reliably detect on its own.
        clicked_pts = get_user_points_vmmc(I);

        if size(clicked_pts, 2) ~= 9
            error('You clicked %d points in %s. You must click exactly 9 points.', size(clicked_pts, 2), files_custom(i).name);
        end

        img_pts_custom{i} = clicked_pts;
    end

    save(custom_points_cache, 'img_pts_custom', 'custom_image_names', 'custom_image_files', 'real_pts_custom', 'tile_size_mm');
    fprintf('Saved custom clicked points to %s.\n', custom_points_cache);
end

H_custom = cell(1, length(files_custom));
for i = 1:length(files_custom)
    % The custom pattern follows the same homography-based calibration
    % procedure as the screen checkerboard, but with manually clicked points.
    H_init = homography_solve_vmmc(real_pts_custom, img_pts_custom{i});
    [H_ref, ~] = homography_refine_vmmc(real_pts_custom, img_pts_custom{i}, H_init);
    H_custom{i} = H_ref;
end

custom_valid_count = numel(H_custom);
if custom_valid_count < 5
    error('Only %d custom calibration images are available. Section 1 requires at least 5.', custom_valid_count);
end

A_prime = internal_parameters_solve_vmmc(H_custom);
assertRealIntrinsicMatrix(A_prime, 'A_prime from custom calibration');
save(fullfile(section_dir, 'A_custom.mat'), 'A_prime');

custom_metrics = computeIntrinsicMetrics(A_prime, img_W_custom, img_H_custom);
[custom_reproj_mean, custom_reproj_errors, custom_reproj_pts] = computeReprojectionCheck( ...
    A_prime, H_custom{1}, real_pts_custom, img_pts_custom{1}, custom_image_files{1}, ...
    fullfile(section_dir, 'reprojection_custom.png'), 'Custom calibration reprojection');

fprintf('\n--- Matrix A_prime (Custom Pattern) ---\n');
disp(A_prime);
printMetrics('Custom calibration', custom_metrics, custom_reproj_mean);

% -------------------------------------------------------------------------
% SECTION 1.2: COMPARISON (A VS A_PRIME)
% -------------------------------------------------------------------------
fprintf('\n======================================================\n');
fprintf('CALIBRATION COMPARISON\n');
fprintf('======================================================\n');

% These comparison values are saved for the written discussion of how the
% precise screen checkerboard and the manual floor-tile calibration differ.
comparison = struct();
comparison.diff_matrix = A - A_prime;
comparison.frobenius_norm = norm(comparison.diff_matrix, 'fro');
comparison.alpha_percent_diff = percentDifference(A(1, 1), A_prime(1, 1));
comparison.beta_percent_diff = percentDifference(A(2, 2), A_prime(2, 2));
comparison.u0_diff_px = A(1, 3) - A_prime(1, 3);
comparison.v0_diff_px = A(2, 3) - A_prime(2, 3);
comparison.skew_diff = A(1, 2) - A_prime(1, 2);
comparison.aspect_ratio_diff = screen_metrics.aspect_ratio - custom_metrics.aspect_ratio;

fprintf('Frobenius norm ||A - A_prime||: %.4f\n', comparison.frobenius_norm);
fprintf('Alpha percent difference: %.4f%%\n', comparison.alpha_percent_diff);
fprintf('Beta percent difference: %.4f%%\n', comparison.beta_percent_diff);
fprintf('Principal point difference: du = %.4f px, dv = %.4f px\n', comparison.u0_diff_px, comparison.v0_diff_px);
fprintf('Skew difference: %.4f\n', comparison.skew_diff);
fprintf('Aspect-ratio difference: %.6f\n', comparison.aspect_ratio_diff);

% -------------------------------------------------------------------------
% SAVE ALL REPORT-READY VALUES
% -------------------------------------------------------------------------
screen = struct();
screen.A = A;
screen.image_files = screen_image_files;
screen.image_names = screen_image_names;
screen.image_width = img_W_screen;
screen.image_height = img_H_screen;
screen.valid_image_count = screen_valid_count;
screen.board_width_mm = board_width_mm;
screen.board_size = screen_board_size;
screen.square_size_mm = screen_square_size_mm;
screen.detected_points = img_pts_screen;
screen.world_points = real_pts_screen;
screen.homographies = H_screen;
screen.metrics = screen_metrics;
screen.reprojection_error_px = screen_reproj_mean;
screen.reprojection_errors_px = screen_reproj_errors;
screen.reprojection_points = screen_reproj_pts;
screen.reprojection_image = screen_image_files{1};
screen.montage_path = fullfile(section_dir, 'montage_screen.png');
screen.reprojection_path = fullfile(section_dir, 'reprojection_screen.png');

custom = struct();
custom.A_prime = A_prime;
custom.image_files = custom_image_files;
custom.image_names = custom_image_names;
custom.image_width = img_W_custom;
custom.image_height = img_H_custom;
custom.valid_image_count = custom_valid_count;
custom.pattern_description = 'Floor-tile planar 3x3 grid';
custom.tile_size_mm = tile_size_mm;
custom.clicked_points = img_pts_custom;
custom.world_points = real_pts_custom;
custom.homographies = H_custom;
custom.metrics = custom_metrics;
custom.reprojection_error_px = custom_reproj_mean;
custom.reprojection_errors_px = custom_reproj_errors;
custom.reprojection_points = custom_reproj_pts;
custom.reprojection_image = custom_image_files{1};
custom.montage_path = fullfile(section_dir, 'montage_custom.png');
custom.reprojection_path = fullfile(section_dir, 'reprojection_custom.png');

save(fullfile(section_dir, 'section1_metrics.mat'), 'screen', 'custom', 'comparison');
writeReportValues(fullfile(section_dir, 'section1_report_values.txt'), screen, custom, comparison);

fprintf('\n>>> Section 1 coding outputs complete. <<<\n');
fprintf('Saved matrices, metrics, point data, metadata, and figures to %s\n', section_dir);
fprintf('Use %s for the DOCX report draft.\n', fullfile(section_dir, 'section1_report_values.txt'));

function files = listImageFiles(folder_path)
    % Collect common image formats and sort them so repeated runs process
    % the calibration images in a stable order.
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

    % Windows file matching is case-insensitive, so patterns such as
    % *.jpeg and *.JPEG can return the same file twice.
    [~, unique_idx] = unique(lower({files.name}), 'stable');
    files = files(unique_idx);

    [~, order] = sort(lower({files.name}));
    files = files(order);
end

function saveMontage(image_files, output_path)
    % A montage gives the report one compact figure showing the calibration
    % views that were actually used.
    fig = figure('Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
    montage(image_files);
    cleanAxesForExport(gca);
    drawnow;
    saveas(fig, output_path);
    close(fig);
end

function metrics = computeIntrinsicMetrics(A, W, H)
    % Convert the intrinsic matrix entries into the lab's required numerical
    % checks. No threshold is imposed here; the values are reported directly.
    metrics = struct();
    metrics.alpha = A(1, 1);
    metrics.beta = A(2, 2);
    metrics.gamma = A(1, 2);
    metrics.u0 = A(1, 3);
    metrics.v0 = A(2, 3);
    metrics.aspect_ratio = metrics.alpha / metrics.beta;
    metrics.aspect_error_percent = 100 * abs(metrics.aspect_ratio - 1);
    metrics.du_from_center_px = metrics.u0 - W / 2;
    metrics.dv_from_center_px = metrics.v0 - H / 2;
    metrics.principal_point_offset_px = sqrt(metrics.du_from_center_px^2 + metrics.dv_from_center_px^2);
    metrics.principal_point_offset_percent = 100 * metrics.principal_point_offset_px / (0.5 * sqrt(W^2 + H^2));
    metrics.orthogonality_measure_deg = atan2d(-metrics.gamma, metrics.alpha);
end

function assertRealIntrinsicMatrix(A, label)
    % Complex or infinite values usually mean the homographies are unstable,
    % so stop immediately instead of saving misleading report numbers.
    if ~isreal(A) || any(~isfinite(A(:)))
        error(['%s is not a valid real finite intrinsic matrix. ', ...
               'Most likely the calibration homographies are unstable. ', ...
               'For custom calibration, re-click the points in exactly the same 3x3 order ', ...
               'on each unique image and make sure all points lie on one flat measured plane.'], label);
    end
end

function [mean_error, errors, projected_pts] = computeReprojectionCheck(A, H, world_pts_2d, image_pts_2d, image_path, output_path, fig_title)
    % Reproject the planar points through one calibrated view to obtain both
    % the numeric mean error and the visual overlay required in the report.
    [R_cell, T_cell] = external_parameters_solve_vmmc(A, {H});
    R = R_cell{1};
    T = T_cell{1};

    npoints = size(world_pts_2d, 2);
    Q = [world_pts_2d; zeros(1, npoints); ones(1, npoints)];
    P = zeros(3, 4, 1);
    P(:, :, 1) = A * [R T];
    q = project_points(P, Q);
    projected_pts = q(1:2, :, 1);

    diffs = projected_pts - image_pts_2d;
    errors = sqrt(sum(diffs.^2, 1));
    mean_error = mean(errors);

    I = imread(image_path);
    fig = figure('Color', 'w', 'Name', fig_title, 'ToolBar', 'none', 'MenuBar', 'none');
    imshow(I);
    ax = gca;
    cleanAxesForExport(ax);
    hold on;
    plot(image_pts_2d(1, :), image_pts_2d(2, :), 'go', 'MarkerSize', 7, 'LineWidth', 1.5);
    plot(projected_pts(1, :), projected_pts(2, :), 'r+', 'MarkerSize', 7, 'LineWidth', 1.5);
    legend({'Detected/clicked points', 'Reprojected points'}, 'Location', 'best');
    title(sprintf('%s: mean error = %.3f px', fig_title, mean_error));
    hold off;
    drawnow;
    saveas(fig, output_path);
    close(fig);
end

function cleanAxesForExport(ax)
    % Disable MATLAB's interactive axes decorations so saved figures look
    % cleaner in the final report.
    try
        disableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Toolbar.Visible = 'off';
    catch
    end
end

function printMetrics(label, metrics, reproj_mean)
    % Echo the same values that will later be written to the report-values
    % file. This makes the MATLAB console useful for quick sanity checks.
    fprintf('\n--- %s metrics ---\n', label);
    fprintf('alpha: %.6f\n', metrics.alpha);
    fprintf('beta: %.6f\n', metrics.beta);
    fprintf('gamma/skew: %.6f\n', metrics.gamma);
    fprintf('principal point: u0 = %.6f, v0 = %.6f\n', metrics.u0, metrics.v0);
    fprintf('aspect ratio alpha/beta: %.6f\n', metrics.aspect_ratio);
    fprintf('aspect-ratio deviation from 1: %.4f%%\n', metrics.aspect_error_percent);
    fprintf('principal-point offset: %.4f px (%.4f%% of half diagonal)\n', ...
        metrics.principal_point_offset_px, metrics.principal_point_offset_percent);
    fprintf('orthogonality measure from skew: %.6f deg\n', metrics.orthogonality_measure_deg);
    fprintf('mean reprojection error: %.4f px\n', reproj_mean);
end

function pct = percentDifference(reference_value, other_value)
    % Use eps in the denominator as a guard against division by zero.
    denom = max(abs(reference_value), eps);
    pct = 100 * abs(reference_value - other_value) / denom;
end

function writeReportValues(output_path, screen, custom, comparison)
    % This text file is the main source for report writing. It keeps all
    % numerical results in one place and avoids copying values from figures.
    fid = fopen(output_path, 'w');
    if fid == -1
        error('Could not open %s for writing.', output_path);
    end
    cleanup_obj = onCleanup(@() fclose(fid));

    fprintf(fid, 'SECTION 1 REPORT VALUES\n');
    fprintf(fid, '=======================\n\n');

    fprintf(fid, '1.1 Screen-checkerboard calibration\n');
    fprintf(fid, '-----------------------------------\n');
    fprintf(fid, 'Image resolution: %d x %d px\n', screen.image_width, screen.image_height);
    fprintf(fid, 'Valid calibration images: %d\n', screen.valid_image_count);
    fprintf(fid, 'Screen checkerboard width: %.4f mm\n', screen.board_width_mm);
    fprintf(fid, 'Detected board size: [%d %d]\n', screen.board_size(1), screen.board_size(2));
    fprintf(fid, 'Square size: %.6f mm\n', screen.square_size_mm);
    fprintf(fid, 'Montage: %s\n', screen.montage_path);
    fprintf(fid, 'Reprojection figure: %s\n\n', screen.reprojection_path);
    writeMatrix(fid, 'A', screen.A);
    writeMetricBlock(fid, screen.metrics, screen.reprojection_error_px);

    fprintf(fid, '\nScreen calibration images used:\n');
    writeCellList(fid, screen.image_names);

    fprintf(fid, '\n1.2 Custom physical pattern calibration\n');
    fprintf(fid, '---------------------------------------\n');
    fprintf(fid, 'Pattern: %s\n', custom.pattern_description);
    fprintf(fid, 'Image resolution: %d x %d px\n', custom.image_width, custom.image_height);
    fprintf(fid, 'Valid calibration images: %d\n', custom.valid_image_count);
    fprintf(fid, 'Tile size: %.4f mm\n', custom.tile_size_mm);
    fprintf(fid, 'Measured point layout: 3 x 3 grid, 9 points\n');
    fprintf(fid, 'Montage: %s\n', custom.montage_path);
    fprintf(fid, 'Reprojection figure: %s\n\n', custom.reprojection_path);
    writeMatrix(fid, 'A_prime', custom.A_prime);
    writeMetricBlock(fid, custom.metrics, custom.reprojection_error_px);

    fprintf(fid, '\nCustom calibration images used:\n');
    writeCellList(fid, custom.image_names);

    fprintf(fid, '\nA vs A_prime comparison\n');
    fprintf(fid, '-----------------------\n');
    fprintf(fid, 'Frobenius norm ||A - A_prime||: %.6f\n', comparison.frobenius_norm);
    fprintf(fid, 'Alpha percent difference: %.6f%%\n', comparison.alpha_percent_diff);
    fprintf(fid, 'Beta percent difference: %.6f%%\n', comparison.beta_percent_diff);
    fprintf(fid, 'Principal point u0 difference: %.6f px\n', comparison.u0_diff_px);
    fprintf(fid, 'Principal point v0 difference: %.6f px\n', comparison.v0_diff_px);
    fprintf(fid, 'Skew difference: %.6f\n', comparison.skew_diff);
    fprintf(fid, 'Aspect-ratio difference: %.6f\n', comparison.aspect_ratio_diff);
end

function writeMetricBlock(fid, metrics, reproj_error)
    % Write one calibration metric block using the same field names for the
    % screen and custom calibrations.
    fprintf(fid, 'alpha: %.6f\n', metrics.alpha);
    fprintf(fid, 'beta: %.6f\n', metrics.beta);
    fprintf(fid, 'gamma/skew: %.6f\n', metrics.gamma);
    fprintf(fid, 'u0: %.6f\n', metrics.u0);
    fprintf(fid, 'v0: %.6f\n', metrics.v0);
    fprintf(fid, 'aspect ratio alpha/beta: %.6f\n', metrics.aspect_ratio);
    fprintf(fid, 'aspect-ratio deviation from 1: %.6f%%\n', metrics.aspect_error_percent);
    fprintf(fid, 'principal-point du from center: %.6f px\n', metrics.du_from_center_px);
    fprintf(fid, 'principal-point dv from center: %.6f px\n', metrics.dv_from_center_px);
    fprintf(fid, 'principal-point offset: %.6f px\n', metrics.principal_point_offset_px);
    fprintf(fid, 'principal-point offset percentage of half diagonal: %.6f%%\n', metrics.principal_point_offset_percent);
    fprintf(fid, 'orthogonality measure from skew: %.6f deg\n', metrics.orthogonality_measure_deg);
    fprintf(fid, 'mean reprojection error: %.6f px\n', reproj_error);
end

function writeMatrix(fid, name, M)
    % Print matrices with fixed precision so they can be pasted directly into
    % the report if needed.
    fprintf(fid, '%s =\n', name);
    for r = 1:size(M, 1)
        fprintf(fid, '  ');
        fprintf(fid, '%14.6f ', M(r, :));
        fprintf(fid, '\n');
    end
    fprintf(fid, '\n');
end

function writeCellList(fid, values)
    % Small helper for readable image-name lists in the report-values file.
    for i = 1:numel(values)
        fprintf(fid, '- %s\n', values{i});
    end
end
