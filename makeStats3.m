%--------------------------------------------------------------------------
% function for calculating statistics
function stats = makeStats3(vals,tempFolder,imgName,map,tr,ty,tg,bdryMeas)

%vals is a column vector of angles (0-90 deg if bdryMeas, 0-180 if ~bdryMeas)
%temp Folder is the output folder
%imgName is the name of the original image file
%map is the 2D map image for counting pixels crossing thresholds
%tr, ty, tg are red, yellow and green thresholds respectively

    if bdryMeas        
        aveAngle = nanmean(vals);
        medAngle = nanmedian(vals);        
        varAngle = nanvar(vals);
        stdAngle = nanstd(vals);        
        alignMent = 0; %not important with a boundary
        skewAngle = skewness(vals); %measure of symmetry
        kurtAngle = kurtosis(vals); %measure of peakedness
        omniAngle = 0; %not important with boundary
    else
        %convert to radians
        %mult by 2, then divide by 2: this is to scale 0 to 180 up to 0 to 360, this makes the analysis circular, since we are using orientations and not directions
        vals2 = 2*(vals*pi/180);
        aveAngle = (180/pi)*circ_mean(vals2)/2;
        aveAngle = mod(180+aveAngle,180);
        medAngle = (180/pi)*circ_median(vals2)/2;        
        medAngle = mod(180+medAngle,180);
        varAngle = circ_var(vals2); %large var means uniform distribution, but not exactly, could be bimodal, between 0 and 1
        stdAngle = circ_std(vals2); 
        alignMent = circ_r(vals2); %large alignment means angles are highly aligned, result is between 0 and 1
        skewAngle = circ_skewness(vals2); %measure of symmetry
        kurtAngle = circ_kurtosis(vals2); %measure of peakedness
        omniAngle = circ_otest(vals2); %this is a p value (significance level), low means the distribution is very aligned, high means uniform or can't tell
    end
    %threshold the map file:
    %count the number of pixels that are greater than the thresholds
    redMap = sum(sum(map>tr));
    yelMap = sum(sum(map>ty))-redMap;
    grnMap = sum(sum(map>tg))-redMap-yelMap;

    stats = vertcat(aveAngle,medAngle,varAngle,stdAngle,alignMent,skewAngle,kurtAngle,omniAngle,redMap,yelMap,grnMap);
    saveStats = fullfile(tempFolder,strcat(imgName,'_stats.csv'));
    csvwrite(saveStats,stats)
end