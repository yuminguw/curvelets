% batch_curveAlignV2_general.m
% This is the batch processing version of curveAlignV2
% 
% All images and boundary files should be in same directory.
% All boundary files should be named "Boundary for imagename.tif.csv" or "Boundary for imagename.tif.tif"
% If there are no boundary files, then program will analyze the images without a
% boundary.
% If there are only a couple boundary files, it will analyze the images
% associated with those boundary files only.
% On start, select any file in the directory of images and boundaries.
% Then select the keep value, distance from boundary, etc.
% All output data is stored in a folder in the starting directory
% 
% Jeremy Bredfeldt, LOCI, Morgridge Institute for Research, December 2012

% To deploy this:
% 1. type mcc -m batch_curveAlignV2_general.m -R '-startmsg,"Starting_Batch_Curve_Align"' at
% the matlab command prompt

% Batch the curvelet process

function batch_curveAlignV2_general()

clear all;
close all;
clc;

%select an input folder
%input folder must have boundary files and images in it
[FileName,topLevelDir] = uigetfile('*.csv;*.tif;*.tiff;*.jpg','Select any file in the input directory: ');
if isequal(FileName,0)
    disp('Cancelled by user');
    return;
end

outDir = [topLevelDir 'CAV2_Output\'];
if ~exist(outDir,'dir')
    mkdir(outDir);
end  

%get directory list in top level dir
fileList = dir(topLevelDir);
%search the directory for boundary files
lenFileList = length(fileList);
bdry_idx = zeros(1,lenFileList);
img_idx = zeros(1,lenFileList);
for i = 1:lenFileList
    if ~isempty(regexp(fileList(i).name,'boundary for', 'once', 'ignorecase'))
        bdry_idx(i) = 1;
    elseif ~isempty(regexp(fileList(i).name,'.tif','once','ignorecase')) || ~isempty(regexp(fileList(i).name,'.jpg','once','ignorecase'))
        img_idx(i) = 1;
    end            
end

bdryTest = ~isempty(find(bdry_idx,1));
if bdryTest
    %if there are boundary files, then only process images with corresponding boundary files
    bdryFiles = fileList(bdry_idx==1);
    numFiles = length(bdryFiles);
    imgFiles(numFiles) = struct('name',[]);
    for i = 1:numFiles
        imgFiles(i).name = bdryFiles(i).name(14:length(bdryFiles(i).name)-4);
    end        
else
    %if there are no boundary files, process all image files
    %find the images in the non boundary files
    imgFiles = fileList(img_idx==1);
    numFiles = length(imgFiles);    
end

if numFiles == 0
    errordlg('Direcory does not contain valid images or boundaries.');
    disp('No valid images or boundaries.');
    return;
end

prompt = {'Enter keep value:','Enter distance thresh (pixels):','Boundary associations? (0 or 1):','Num to process:','Use FIRE results? (0 = no or 1 = yes):'};
dlg_title = 'Input for batch CA';
num_lines = 1;
def = {'0.05','137','0',num2str(numFiles),'0'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
if isempty(answer)
    disp('Cancelled by user');
    return;
end
keep = str2num(answer{1});
distThresh = str2num(answer{2}); %pixels
makeAssoc = str2num(answer{3});
numToProc = str2num(answer{4});
useFire = str2num(answer{5});
fireDir = [];

if useFire
    [fireFname,fireDir] = uigetfile('*.mat','Select directory containing fire results: ');
    if isequal(fireFname,0)
        disp('Cancelled by user');
        return;
    end    
end

disp(['Will process ' num2str(numToProc) ' images.']);
fileNum = 0;
tifBoundary = 0;
bdryImg = 0;

for j = 1:numToProc
    fileNum = fileNum + 1;
    disp(['file number = ' num2str(fileNum)]);
    coords = []; %start with coords empty
    if bdryTest
        bdryName = bdryFiles(j).name;
        if isequal(bdryName(end-2:end),'tif') || isequal(bdryName(end-3:end),'tiff')
            %check if boundary file is a tiff file, multiple boundaries
            tifBoundary = 1;
            bff = [topLevelDir bdryName];
            bInfo = imfinfo(bff);
            bNumSections = numel(bInfo);
        else    
            coords = csvread([topLevelDir bdryName]);                                
        end
        disp(['boundary name = ' bdryName]);
    end
    
    imageName = imgFiles(j).name;
    %check if filename is annotated with normal or control
    if ~isempty(regexp(imageName,'control','once','ignorecase')) || ~isempty(regexp(imageName,'normal','once','ignorecase'))
        NorT = 'N';            
    else
        NorT = 'T';            
    end
    
    ff = [topLevelDir imageName];               
    %check if image file exists, if not, skip to next boundary file
    if ~exist(ff,'file')
        disp([imageName ' does not exist. Skipping to next file.']);
        continue;
    end     
    
    info = imfinfo(ff);
    numSections = numel(info);    
    if tifBoundary
        %check if boundary file and image file have the same numer of sections
        if numSections ~= bNumSections
            disp(['Image has ' num2str(numSections) ' images, while boundary has ' num2str(bNumSections) ' images! Skipping!']);
            continue;
        end
        %check if boundary image is the same size as the SHG image
        if bInfo.Width ~= info.Width || bInfo.Height ~= info.Height
            disp(['SHG and boundary images are different sizes! Skipping!']);
            continue;
        end
    end
    
    for i = 1:numSections     
        if numSections > 1
            img = imread(ff,i,'Info',info);
            if tifBoundary
                bdryImg = imread(bff,i,'Info',bInfo);
            end
        else
            img = imread(ff);
            if size(img,3) > 1
                %if rgb, pick one color
                img = img(:,:,1);
            end
            
            if tifBoundary
                bdryImg = imread(bff);
            end
        end
        
        if tifBoundary            
            linCoords = find(bdryImg > 0);%boundary file must be a mask image (only 0 and 255)
            [coordsy coordsx] = ind2sub(size(bdryImg),linCoords); %now these are 2D coordinates in the image frame
            coords = [coordsy coordsx];
        end
        %%
        disp(['computing curvelet transform on slice ' num2str(i)]);      
        [histData,~,~,values,distances,stats,map] = processImage(img, imageName, outDir, keep, coords, distThresh, makeAssoc, i, 0, tifBoundary, bdryImg, fireDir);
        writeAllHistData2(histData, NorT, outDir, fileNum, stats, imageName, i);
    end
    disp(['done processing ' imageName]);    
end        

disp(['processed ' num2str(fileNum) ' images.']);

end