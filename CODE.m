fileFolder = fullfile(pwd, '08');
files = dir(fullfile(fileFolder, '*dcm'));
fileNames = {files.name};

info = dicominfo(fullfile(fileFolder, fileNames{1}));
display(info);

voxel_size = [info.PixelSpacing; info.SliceThickness]';
display(voxel_size);

numImages = length(fileNames);
display(numImages);

mri = zeros(info.Rows, info.Columns, numImages, class(info.BitsAllocated));
 
for i = 1:length(fileNames)
   fname = fullfile(fileFolder, fileNames{i}); 
   mri(:,:,i) = uint16(dicomread(fname));  
end

figure;
montage(reshape(uint16(mri), [size(mri,1), size(mri,2),1, size(mri,3)]),'DisplayRange',[]);
set(gca, 'clim', [0, 500]);
drawnow;
shg;

D = zeros(info.Rows, info.Columns, numImages, class(info.BitsAllocated));
D(:,:,1:21) = mri(:,:,36:end);
D(:,:,22:end) = mri(:,:,1:35);
figure;
montage(reshape(uint16(D), [size(D,1), size(D,2),1, size(D,3)]),'DisplayRange',[]);
set(gca, 'clim', [0, 500]);
drawnow;
shg;

im = D(:,:,32);
max_level = double(max(im(:)));
imt = imtool(im, [0, max_level]);

lb = 60;  % lower threshold
ub = 285; % upper threshold


mriAdjust = D;
mriAdjust(mriAdjust <= lb) = 0;
mriAdjust(mriAdjust >= ub) = 0;
mriAdjust(:,:,1:25) = 0;
mriAdjust(:,:,46:56) = 0;
bw = logical(mriAdjust);

% smoothing
nhood = ones([5 5 1]);
bw = imopen(bw,nhood);
figure;
subplot(1,2,1);imshow(D(:,:,32),[0, max_level]);
subplot(1,2,2);imshow(bw(:,:,32));

nhood = ones([5 5 1]);
bw = imopen(bw,nhood);
figure;
subplot(1,2,1);imshow(D(:,:,32),[0, max_level]);
subplot(1,2,2);imshow(bw(:,:,32));

L        = bwlabeln(bw);
stats    = regionprops(L, 'Area','Centroid');

A        = [stats.Area];
biggest  = find(A == max(A));
mriAdjust(L ~= biggest) = 0;

imA      = imadjust(mriAdjust(:,:,32));
figure;
imshow(imA);
figure;
montage(reshape(uint16(mriAdjust), [size(mriAdjust,1), size(mriAdjust,2),1, size(mriAdjust,3)]),'DisplayRange',[]);
drawnow;
shg;

thresh_tool(uint16(mriAdjust(:,:,32)), 'gray');
level = 190;

mriBrainPartition = uint8(zeros(size(mriAdjust)));
mriBrainPartition(mriAdjust>lb & mriAdjust<level) = 2;
mriBrainPartition(mriAdjust>=level) = 20;
figure;
imshow(mriBrainPartition(:,:,32), [0 0 0; 0.1 0.1 0.1; 0.25 0.25 0.25;0.25 0.25 0.8]);
figure;
montage(mriBrainPartition,'Size', [7 7],'DisplayRange', [0 20]);

cm = brighten(jet(60),-0.5);
figure('Colormap', cm)
contourslice(mriAdjust, [], [], 32)
axis ij tight
daspect([1,1,1])
