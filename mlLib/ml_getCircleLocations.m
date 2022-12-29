% GET X,Y VALUES FOR POINTS ON A CIRCULAR PATH
% 20-Nov-2021 - Thomas

function locs = ml_getCircleLocations(nPoints, radius, rotation, figflag, holdLocs, holdLocsCenterFlag)
if~exist('rotation','var'),            rotation            = 0; end
if~exist('figflag','var'),             figflag             = 1; end
if~exist('holdLocs','var'),            holdLocs            = [0 0]; end
if~exist('holdLocsCenterFlag','var'),  holdLocsCenterFlag  = 0; end

% SCREEN resolution for Elo 1593L in series4
pixPerDVA    = 19.185;
screenDimPx  = [1366 768];
screenDimDVA = screenDimPx./pixPerDVA;

% CALCULATE the rotation required in pi units
rotationPi = (2*pi/360) * rotation; % we are working in pi units for angles

% CREATE equidistant points in 0 to 2*pi (360 degree) angles
theta = linspace(0,2*pi,nPoints + 1) + rotationPi ;

% CALCULATE the x and y values for each point at radius
x    = radius*cos(theta(1:nPoints));
y    = radius*sin(theta(1:nPoints));
locs = [x' y'];

% Recentre them to holdLoc if requested
if holdLocsCenterFlag
    locs(:,1) = locs(:,1) + holdLocs(1);
    locs(:,2) = locs(:,2) + holdLocs(2);
end

% IF user wants to plot and see each calculated point on the circle
if figflag
    % OPEN figure 
    figure
    fprintf('\nPLOTTING each point on the circle\n')
    fprintf('---------------------------------\n')
    fprintf('\nPress any key to plot the next point\n')
    
    % PLOT the hold button
    viscircles(holdLocs,4)
    hold on
    
    % PLOT point by point
    for i = 1:nPoints
        plot(locs(i,1),locs(i,2),'.k','MarkerSize',20)
        text(locs(i,1).*(1+0.1),locs(i,2).*(1+0.1), sprintf('%d',i),'Color','r')

    end
    
    % SET the axis limits
    axis equal
    xlim([-screenDimDVA(1)/2 screenDimDVA(1)/2])
    ylim([-screenDimDVA(2)/2 screenDimDVA(2)/2])
%     hold on
%     axis equal
end
end