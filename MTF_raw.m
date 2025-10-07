% Quick and Dirty MTF Measurement (ROI + Multiple Band Averaging)

clear;

%% --- Step 1: Load Image ---
img = imread('chart.jpg');   % Replace with your image filename
if size(img,3) == 3
    img_gray = rgb2gray(img);
else
    img_gray = img;
end

%% --- Step 2: Select ROI around the slanted edge ---
figure;
imshow(img_gray, []);
title('Draw a rectangle ROI around the slanted edge');
roi_rect = getrect;  % [xmin, ymin, width, height]
roi = imcrop(img_gray, roi_rect);

%% --- Step 2: Select ROI around the slanted edge ---

% --- Show original image with ROI marked ---
figure;
imshow(img_gray, []);
hold on;
rectangle('Position', roi_rect, 'EdgeColor','g','LineWidth',2);
title(sprintf('Selected ROI (x=%.0f, y=%.0f, w=%.0f, h=%.0f)', ...
    roi_rect(1), roi_rect(2), roi_rect(3), roi_rect(4)));

% --- Show cropped ROI itself ---
figure;
imshow(roi, []);
title('Cropped ROI (Slanted Edge)');

% --- Print ROI coordinates in command window ---
fprintf('ROI selected: x=%.0f, y=%.0f, width=%.0f, height=%.0f\n', ...
    roi_rect(1), roi_rect(2), roi_rect(3), roi_rect(4));

%% --- Step 3: Parameters for averaging ---
[rowCount, colCount] = size(roi);
num_bands = 10;                % how many horizontal bands to split ROI into
band_height = floor(rowCount/num_bands);

all_mtf = [];
all_esf = [];

%% --- Step 4: Process each band ---
for b = 1:num_bands
    y0 = (b-1)*band_height + 1;
    y1 = min(b*band_height, rowCount);
    subBand = roi(y0:y1, :);

    % ESF = average across rows of this band
    esf = mean(double(subBand), 1);
    all_esf = [all_esf; esf(:)'];   % store all ESFs

    % --- LSF ---
    lsf = diff(esf);

    % --- FFT of LSF ---
    N = length(lsf);
    fftVals = fft(lsf);
    fftMag = abs(fftVals(1:floor(N/2)));   % modulus, positive half only
    mtf = fftMag / max(fftMag);

    % store MTF
    all_mtf = [all_mtf; mtf(:)'];
end

%% --- Step 5: Average ESF, LSF, and MTF ---
esf_avg = mean(all_esf, 1);
lsf_avg = diff(esf_avg);
mtf_avg = mean(all_mtf, 1);

% Frequency axis in cycles/pixel
N = size(all_mtf, 2);
freq_cyc_per_pix = linspace(0, 0.5, N);

%% --- Step 6: Convert to lp/mm (using pixel pitch) ---
pixel_size_mm = 0.0014;   % 1.4 µm = 0.0014 mm
freqs_lpmm = freq_cyc_per_pix / pixel_size_mm;

%% --- Step 7: Plot ESF ---
figure;
plot(esf_avg, 'LineWidth', 1.5);
xlabel('Pixel position');
ylabel('Intensity');
title('Edge Spread Function (ESF)');
grid on;

%% --- Step 8: Plot LSF ---
figure;
plot(lsf_avg, 'LineWidth', 1.5);
xlabel('Pixel position');
ylabel('dI/dx');
title('Line Spread Function (LSF)');
grid on;

%% --- Step 9: Plot Averaged MTF with cutoff markers ---
figure;
plot(freqs_lpmm, mtf_avg, 'k-', 'LineWidth', 1.5); hold on;

% Add horizontal line for MTF=0.5
yline(0.5, 'r--', 'MTF = 0.5', ...
    'LabelHorizontalAlignment','left', 'LabelVerticalAlignment','bottom');

% Find MTF50 cutoff and mark it
idx = find(mtf_avg <= 0.5, 1, 'first');
if ~isempty(idx)
    cutoff_lpmm = freqs_lpmm(idx);
    xline(cutoff_lpmm, 'b--', ...
        sprintf('Resolution = %.2f lp/mm at MTF=0.5', cutoff_lpmm), ...
        'LabelOrientation','horizontal', ...
        'LabelHorizontalAlignment','left', ...
        'LabelVerticalAlignment','bottom');
else
    cutoff_lpmm = NaN;
end

xlabel('Spatial Frequency (lp/mm)');
ylabel('Normalized MTF');
title('Averaged Modulation Transfer Function (MTF)');
grid on;
legend('Averaged MTF', 'Location','northeast');


 