% 1. Read the input image
% Replace 'input.jpg' with your actual image file name
img = imread('input.jpg'); 

% ==========================================
% Resize the image to 128x128 pixels
img = imresize(img, [128, 128]);
% ==========================================

% Get the dimensions of the image (This will now be 128 and 128)
[rows, cols, channels] = size(img);

% Convert the image to double for manual mathematical operations
img_double = double(img);

% 2. Manual Grayscale Conversion (without using rgb2gray)
if channels == 3
    % Standard luminance formula: Grayscale = 0.2989*R + 0.5870*G + 0.1140*B
    R = img_double(:, :, 1);
    G = img_double(:, :, 2);
    B = img_double(:, :, 3);

    % Note: Fixed the missing multiplication (*) signs here
    gray_img_double = (0.2989 * R) + (0.5870 * G) + (0.1140 * B);
else
    gray_img_double = img_double;
end

% Convert back to 8-bit unsigned integer (0-255)
gray_img = uint8(gray_img_double);

% 3. Manual Salt and Pepper Noise Application (without using imnoise)
noisy_img = gray_img;
noise_density = 0.05; % Set the density of the noise (5%)

% Generate a matrix of random numbers uniformly distributed between 0 and 1
rand_matrix = rand(rows, cols);

% Apply Pepper (black dots = 0) 
% For random values between 0 and noise_density/2
noisy_img(rand_matrix < (noise_density / 2)) = 0;

% Apply Salt (white dots = 255)
% For random values between noise_density/2 and noise_density
noisy_img((rand_matrix >= (noise_density / 2)) & (rand_matrix < noise_density)) = 255;

% Display images to verify the results visually
figure;
subplot(1, 2, 1); imshow(gray_img); title('Manual Grayscale Image');
subplot(1, 2, 2); imshow(noisy_img); title('Manual Salt & Pepper Noise');

% 4. Save data to .coe file in Base 10
% Transpose so we can read the image row by row (raster scan)
img_transposed = noisy_img'; 
img_1d = img_transposed(:); % Flatten into a 1D array

% Open file for writing
fileID = fopen('image_data.coe', 'w');

if fileID == -1
    error('Error: Cannot open the file for writing.');
end

% Write the COE file header for base 10 (decimal)
fprintf(fileID, 'memory_initialization_radix=10;\n');
fprintf(fileID, 'memory_initialization_vector=\n');

% Write the pixel values in decimal format
total_pixels = length(img_1d);
for i = 1:total_pixels
    if i == total_pixels
        % The last value must end with a semicolon
        fprintf(fileID, '%d;', img_1d(i)); 
    else
        % Other values are separated by a comma
        fprintf(fileID, '%d,\n', img_1d(i)); 
    end
end

% Close the file
fclose(fileID);

% Print success message
disp('Success: The image_data.coe file has been generated in Base 10.');