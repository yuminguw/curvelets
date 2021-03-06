%--------------------------------------------------------------------------
% draw curvelets on an image as points (centers) and lines
% Jeremy Bredfeldt and Yuming Liu 2012

function drawCurvs(object, Ax, len, color_flag)

% object is the struct generated by the newCurve function
% Ax is the handle to the figure axes
% len is the length of the curvelet line
% color_flag indicates if you want the curvelets to be green (0) or red (1)

    for ii = 1:length(object)
        ca = object(ii).angle*pi/180;
        xc = object(ii).center(1,2);
        %yc = size(IMG,1)+1-r(ii).center(1,1);
        yc = object(ii).center(1,1);
        if (color_flag == 0)
            plot(xc,yc,'g.','MarkerSize',5,'Parent',Ax); % show curvelet center     
        else
            plot(xc,yc,'r.','MarkerSize',5,'Parent',Ax); % show curvelet center     
        end            

        % show curvelet direction
        xc1 = (xc - len * cos(ca));
        xc2 = (xc + len * cos(ca));
        yc1 = (yc + len * sin(ca));
        yc2 = (yc - len * sin(ca));
        if (color_flag == 0)
            plot([xc1 xc2],[yc1 yc2],'g-','linewidth',0.7,'Parent',Ax); % show curvelet angle
        else
            plot([xc1 xc2],[yc1 yc2],'r-','linewidth',0.7,'Parent',Ax); % show curvelet angle
        end
    end
end