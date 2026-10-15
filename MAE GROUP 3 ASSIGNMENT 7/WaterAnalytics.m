clc; clear;
start_toolkit;
d = epanet('WaterAnalytics.inp'); % Load a network

% plotting Networks
d.plot; % Plot network topology
d.plot('nodes', 'yes', 'fontsize', 12); % Plot nodes IDs
d.plot('links', 'yes', 'fontsize', 12); % Plot links IDs
d.plot('links', 'yes', 'highlightlink',{'10'}, 'fontsize',8); % Highlight specific links
d.plot('point', 'no'); % plot only links
d.plot('line', 'no'); % Plot inly nodes

% Plot graph
h = d.plotGraph;
title('Network Graph');
d.plotGraph('nodes', 'yes'); % Show ID of nodes
title('Network Graph with node IDs');
d.plot('legend', 'hide'); % Hide legend 

% Highlight links with different colors
linkSet1 = d.getLinkNameID(1:4);
colorLinkSet1 = repmat({'r'},1,length(linkSet1));
linkSet2 = d.getLinkNameID([5,6,7,8]);
colorLinkSet2=repmat({'g'},1,length(linkSet2));
d.plot('highlightlink',[linkSet1 linkSet2],'colorlink',[colorLinkSet1 colorLinkSet2])

% Hydraulic Analysis
% etstep = 3600;
% d.setTimeReportingStep(etstep);
% d.setTimeHydraulicStep(etstep);
% d.setTimeQualityStep(etstep);
tic;
d.openHydraulicAnalysis;
d.initializeHydraulicAnalysis;
tstep=1;P=[];T_H=[];
while (tstep>0)
    t=d.runHydraulicAnalysis;
    P=[P; d.getNodePressure];
    T_H=[T_H; t];
    tstep=d.nextHydraulicAnalysisStep;
end
d.closeHydraulicAnalysis;
time_4 = toc;

% Hydraulic analysis using ENepanet binary file (This function ignore events)
hyd_res = d.getComputedHydraulicTimeSeries('time', 'pressure', 'flow', 'velocity');

% Change time-stamps from seconds to hours
hrs_time = hyd_res.Time/3600;

% Hydraulic analysis using ENepanet binary file.
hyd_res = d.getComputedTimeSeries;

% Get node and link info.
times = hyd_res.Time;  % get time stamps
color = 'g';  % choose color
nodenameid = d.getNodeNameID;  % get node IDs
linknameid = d.getLinkNameID;  % get link IDs
nodesconnlinks = d.getNodesConnectingLinksID;  % get node connectivity
nodecoords = d.getNodeCoordinates;  % get node coordinates

% Set custom offset for text.
x = nodecoords{1};
y = nodecoords{2};
min_coorx = min(x);
min_coory = min(y);
max_coorx = max(x);
max_coory = max(y);
xsenoff = (max_coorx - min_coorx) * 0.075;
ysenoff = (max_coory - min_coory) * 0.03;

% Get plot axes.
fig = d.plot('legend', 'hide');
format long g

fprintf('\n');
% Computed Hydraulic & Quality Time Series via ENepanet binary file.
d.solveCompleteHydraulics;
Results = d.getComputedTimeSeries;

nodeID = '10';
indexNode = d.getNodeIndex(nodeID);
disp(['Plotting: ' nodeID ' index=' num2str(indexNode)]);

% Plot pressures.
figure;
subplot(2,1,1);
plot(Results.Time/3600, Results.Pressure(:,indexNode));
title('Before set curve');
xlabel('Time (hrs)'); 
ylabel(['Pressure (', d.NodePressureUnits,')'])  
grid on;

% comparing simulations
% Set simulation duration.
hours = 100;
d.setTimeSimulationDuration(hours*3600);

% Test hydraulics and quality analysis functions.
Results = d.getComputedTimeSeries
tocResults =tic;

% Using the functions(ENopenH, ENinit, ENrunH, ENgetnodevalue/&ENgetlinkvalue, ENnextH, ENcloseH).
Hydraulics = d.getComputedHydraulicTimeSeries('flow', 'time') 
tocHydraulics = toc;tic;

% ENopenQ, ENinitQ, ENrunQ, ENgetnodevalue/&ENgetlinkvalue, ENstepQ, ENcloseQ
Quality = d.getComputedQualityTimeSeries
tocQuality = toc;tic;

pipeindex=4;
nodeindex=6;

% Step by step hydraulic analysis.
d.openHydraulicAnalysis;
d.initializeHydraulicAnalysis;
tstep=1;P=[];T_H=[];D=[];H=[];F=[];
while (tstep>0)
    t=d.runHydraulicAnalysis;
    P=[P; d.getNodePressure];
    D=[D; d.getNodeActualDemand];
    H=[H; d.getNodeHydraulicHead];
    F=[F; d.getLinkFlows];
    T_H=[T_H; t];
    tstep=d.nextHydraulicAnalysisStep;
end
d.closeHydraulicAnalysis

% Step by step quality analysis.
d.openQualityAnalysis
d.initializeQualityAnalysis
tleft=1; P=[];T_Q=[];Q=[];  
sim_duration = d.getTimeSimulationDuration();
while (tleft>0 || t < sim_duration)
    t=d.runQualityAnalysis;
    Q=[Q; d.getNodeActualQuality];
    T_Q=[T_Q; t];
    tleft = d.stepQualityAnalysisTimeLeft;
end
d.closeQualityAnalysis;

% fprintf('\nSimulation duration: d hours\n', hours);
disp(['Run Time of function d.getComputedTimeSeries: ', num2str(tocResults), '(sec)'])
disp(['Run Time of function d.getComputedHydraulicTimeSeries: ', num2str(tocHydraulics), '(sec)'])
disp(['Run Time of function d.getComputedQualityTimeSeries: ', num2str(tocQuality), '(sec)'])

figure;
plot(Results.Time, Results.Flow(:,pipeindex));
title('d.getComputedTimeSeries (Ignore events)');
xlabel('Time (sec)'); ylabel(['Flow (',d.LinkFlowUnits,') - Link ID "',d.LinkNameID{pipeindex},'"'])
set(gca,'XTickLabel',num2str(get(gca,'XTick').'));

figure;
plot(T_H, F(:,pipeindex));
title('step by step Hydraulic Analysis');
xlabel('Time (sec)'); ylabel(['Flow (',d.LinkFlowUnits,') - Link ID "',d.LinkNameID{pipeindex},'"'])
set(gca,'XTickLabel',num2str(get(gca,'XTick').'));

figure;
plot(Results.Time, Results.NodeQuality(:,nodeindex));
title('d.getComputedTimeSeries (Ignore events)');
xlabel('Time (sec)'); ylabel(['Node Quality (',d.QualityChemUnits,') - Node ID "',d.NodeNameID{nodeindex},'"'])
set(gca,'XTickLabel',num2str(get(gca,'XTick').'));

figure;
plot(Quality.Time, Quality.NodeQuality(:,nodeindex));
title('d.getComputedQualityTimeSeries');
xlabel('Time (sec)'); ylabel(['Node Quality (',d.QualityChemUnits,') - Link ID "',d.NodeNameID{nodeindex},'"'])
set(gca,'XTickLabel',num2str(get(gca,'XTick').'));


% Link index for change the status.
link_index=2;
Status = [0 0 0 0 0 1 1 0 0 1 0 1 0 1 0 1 0 1 0 1 0 0 0 0 1 1]';

% Assigning curve pump
%Add new curve in the network.
indexCurve=d.addCurve('NewCurve', [1500 300; 1800 500]);

% Pattern times
% Get times.
t = d.getBinTimesInfo;
hydstep = t.BinTimeHydraulicStep;
duration = t.BinTimeSimulationDuration;

% Create random settings.
a = 60; b = 90;
settings = (b-a).*rand((duration/hydstep)+1,1) + a;
 
% Settings for valve 'VALVE-173'.
valveID = 'VALVE-173';
valveIndex = d.getBinLinkIndex(valveID);

% check pressures at node after valve.
nodeIndex = d.getBinNodeIndex('JUNCTION-112');
settings = num2str(settings,'%04.4f');

hrs = duration/3600;
hours = 0:hrs;
step = 0:hydstep/60:55; % step 30min
i=1; Time = cell(hrs,1);
for u=1:hrs
    for j=1:length(step)
        Time{i} = sprintf('%03d:%02d:00',hours(u),step(j));
        Controls(i,: ) = ['LINK ',valveID,' ',settings(i,:),' AT TIME ',Time{i}];
        i=i+1;
    end
end

d.addBinControl(Controls);

% Run simulation with executable.
d.setCMDCODE(1)  % hide cmd messages..
Sim = d.getBinComputedAllParameters;
d.BinClose;

disp('Create random settings')
disp('----------------------')
disp('a = 60; b = 90;')
disp('settings = (b-a).*rand((duration/hydstep)+1,1) + a;')

disp('Add CV PIPE with Bin Functions addBinJunction')
 
% Plot network with bin functions.
d.Binplot('nodes','yes');
 
% Plot normal with new pipe.
d.plot('links','yes');

% Get from and to nodes for add cv pipe.
fromNode = d.getBinNodeNameID.BinNodeNameID{2};
toNode = d.getBinNodeNameID.BinNodeNameID{6};

% Plot network with changes.
d.Binplot('links','yes');

% add a cv pipe
disp('Add a CV pipe')
d.plot;

% Get from and to nodes for add cv pipe.
fromNode = d.getNodeNameID{2};
toNode = d.getNodeNameID{6};
node_index = d.addLinkPipeCV('CVPipe',fromNode,toNode);

% Plot new network with changes.
d.plot('links','yes');

% hydraulic and quality analysis
d.setQualityType('Chlorine', 'mg/L');
initialQuality = 0.6;
nodeIndex = d.getNodeReservoirIndex;
nodeIndex = [nodeIndex d.getNodeTankIndex];
d.setNodeInitialQuality(nodeIndex, initialQuality * ones(length(nodeIndex),1))

% Set time hydraulic and quality steps
etstep = 3600;
d.setTimeReportingStep(etstep);
d.setTimeHydraulicStep(etstep);
d.setTimeQualityStep(etstep);
 
% Hydraulic and Quality analysis STEP-BY-STEP.
d.openHydraulicAnalysis;
d.openQualityAnalysis;
d.initializeHydraulicAnalysis(0);
d.initializeQualityAnalysis(d.ToolkitConstants.EN_NOSAVE);

tstep = 1;
T = []; P = []; F = []; QN = []; QL = [];
while (tstep>0)
    t = d.runHydraulicAnalysis;
    qt = d.runQualityAnalysis;

    P = [P; d.getNodePressure];
    F = [F; d.getLinkFlows];
    
    QN = [QN; d.getNodeActualQuality];
    QL = [QL; d.getLinkActualQuality];
    T = [T; t];

    tstep = d.nextHydraulicAnalysisStep;
    qtstep = d.nextQualityAnalysisStep;
end
d.closeQualityAnalysis;
d.closeHydraulicAnalysis;

% Display nodes pressures, links flows, nodes actual qualities, links actual qualities.
P;
F;
QN;
QL;

% create multiple scenarios
% Create scenario parameters.
% TIMES
PatternTimeStep=d.TimePatternStep;
SimulationTime=48; %e.g.48 in Hours

% CONTAMINANT (A)
SourceInjectionRate=10; %mg/L (Concentration), instead of mg/minute
SourcesInjectionTimes=[5 20]; %from...to in hours

% Uncertainty
qunc=0.05;

% Get times.
hydstep = d.getTimeHydraulicStep;
duration = d.getTimeSimulationDuration;

% Get Pipe infos.
pipe_count = d.getLinkPipeCount;
pipeIDs = d.getLinkPipeNameID;

% Find the max length of link pipe names.
spsmax = max(cellfun('length',pipeIDs));

% Times.
hrs = duration/3600;
hours = 0:hrs;
step = 0:hydstep/60:55; %step 30min
i=1; Time = cell(hrs,1);

disp('Create random status')
figure;
RES = d.getComputedHydraulicTimeSeries('flow');
plot(RES.Flow);
title('Change status of pipes every hour');
xlabel('Time (hours)');

% Get pipe count.
pipe_count = d.getLinkPipeCount;

% Get pipe indices.
pipe_indices = d.getLinkPipeIndex;

% rotate network
% Rotate degrees theta.
theta = pi/3; %60 degrees

% Define the x- and y-data for the original line we would like to rotate.
x = d.getNodeCoordinates{1}';
y = d.getNodeCoordinates{2}';

% Create a matrix of these points, which will be useful in future calculations.
v = [x;y];

% Choose a point which will be the center of rotation.
x_center = x(1);
y_center = y(1);

% Create a matrix which will be used later in calculations.
center = repmat([x_center; y_center], 1, length(x));

% Define a 60 degree counter-clockwise rotation matrix.
% theta = pi/3;       % pi/3 radians = 60 degrees
R = [cos(theta) -sin(theta); sin(theta) cos(theta)];

% testing pressure driven analysis
% Set Demand Multiplier to 10 to cause negative pressures.
d.setOptionsPatternDemandMultiplier(10);

% Run single period analysis.
d.setTimeSimulationDuration(0);

% Solve hydraulics with default DDA option which will return with neg. pressure warning code.
d.solveCompleteHydraulics;

% Check that 4 demand nodes have negative pressures.
deficient_nodes = d.getStatistic.DeficientNodes;
check_error(abs(deficient_nodes) == 4)

% Switch to PDA with pressure limits of 20 - 100 psi.
type = 'PDA';
pmin = 0;
preq = 0.1;
pexp = 0.5;
d.setDemandModel(type, pmin, preq, pexp);

% Solve hydraulics again.
d.solveCompleteHydraulics;

% Check that Junction 6 had full demand.
junctionIndex_6 = d.getNodeIndex('6');
demand_deficit_6 = d.getNodeDemandDeficit(junctionIndex_6);
check_error(abs(demand_deficit_6) < 0.01)

% Check that Junction 8 had a demand deficit of 413.67.
junctionIndex_8 = d.getNodeIndex('8');
demand_deficit_8 = d.getNodeDemandDeficit(junctionIndex_8);
check_error(abs(demand_deficit_8 - 413.67) < 0.01)

% change connections of links
% Examples: >> help d.getLinkNodesIndex
linkIndex = 3;
% d.getLinkNameID % d.getNodeNameID

%Get all link node indices
linkNodes = d.getLinkNodesIndex(linkIndex);
disp(linkNodes);

% Examples: >> help d.setLinkNodesIndex
startNode = 2;
endNode = 4;

% Set link node indices for specific link index
d.setLinkNodesIndex(linkIndex, startNode, endNode)
disp(d.getLinkNodesIndex(linkIndex))
% d.getLinkNodesIndex

%Reverse a link
d.getLinkNodesIndex(linkIndex)
d.reverseLinkNodeIndices(linkIndex)
d.getLinkNodesIndex(linkIndex)

% change node name
disp('Node name ids:')
d.getNodeNameID'

% Set your prefix
junction_prefix = 'J';
reservoir_prefix = 'R';
tank_prefix = 'T';

% Update node names
for i=d.getNodeJunctionIndex
    d.setNodeNameID(i, [junction_prefix, '-', num2str(i)]);
end

for i=d.getNodeReservoirIndex
    d.setNodeNameID(i, [reservoir_prefix, '-', num2str(i)]);
end

for i=d.getNodeTankIndex
    d.setNodeNameID(i, [tank_prefix, '-', num2str(i)]);
end

disp('Node name ids after:')
d.getNodeNameID'

% Load network
G = epanet('Net1.inp');
Fmean = mean(G.getComputedHydraulicTimeSeries('flow').Flow,1);

% Compute the new adjacency matrix based on the mean flow in the network
Fsign = sign(Fmean);
Nidx = G.getLinkNodesIndex;
for i = 1:size(Nidx,1)
    if Fsign(i) == 1
        A(Nidx(i,1),Nidx(i,2)) = 1;
    else
        A(Nidx(i,2),Nidx(i,1)) = 1;
    end
end
A

% Run complete analysis.
values = d.getComputedTimeSeries;

% Create json text variables from single or many variables.
demsJsonTxt = d.toJson(values.Demand)
flowJsonTxt = d.toJson(values.Flow)
allJsonTxt = d.toJson(values)

% Create json files containing all variables from the analysis.
d.toJsonFile(values.Flow, 'Flows'); % input: value, filename (.json)
d.toJsonFile(values, 'AllValues');

% leakage
q_unit = d.getFlowUnits();
p_unit = d.getOptionsPressureUnits();
fprintf('[Units] Flow=%s | Pressure=%s\n', q_unit, p_unit);

% Simulation settings
SIM_HOURS    = 24;
HYD_STEP_MIN = 60;

d.setTimeSimulationDuration(SIM_HOURS * 3600);
d.setTimeHydraulicStep(HYD_STEP_MIN * 60);

nLinks = d.getLinkCount();

% Create a network with EN api functions
% Use gpm for flow units and the Hazen-Williams formula for head loss
d.apiENinit(d.ToolkitConstants.EN_GPM, d.ToolkitConstants.EN_HW, d.LibEPANET, d.ph);

% Add the first junction node to the project with an elevation of 700 ft and a demand of 0
[index, ~]  = d.apiENaddnode('J1', d.ToolkitConstants.EN_JUNCTION, d.LibEPANET, d.ph);
d.apiENsetjuncdata(index, 700, 0, '', d.LibEPANET, d.ph);
d.apiENsetcoord(index, 0, 0, d.LibEPANET, d.ph);

% Add the remaining two junctions with elevations of 710 ft and demands of 250 and 500 gpm, respectively
[index, ~]  = d.apiENaddnode('J2', d.ToolkitConstants.EN_JUNCTION, d.LibEPANET, d.ph);
d.apiENsetjuncdata(index, 710, 250, '', d.LibEPANET, d.ph);
d.apiENsetcoord(index, 0, -100, d.LibEPANET, d.ph);
[index, ~]  = d.apiENaddnode('J3', d.ToolkitConstants.EN_JUNCTION, d.LibEPANET, d.ph);
d.apiENsetjuncdata(index, 710, 500, '', d.LibEPANET, d.ph);
d.apiENsetcoord(index, 100, 0, d.LibEPANET, d.ph);

% Add the reservoir at an elevation of 650 ft
[index, ~]  = d.apiENaddnode('R1', d.ToolkitConstants.EN_RESERVOIR, d.LibEPANET, d.ph);
d.apiENsetnodevalue(index, d.ToolkitConstants.EN_ELEVATION, 650, d.LibEPANET, d.ph);
d.apiENsetcoord(index, -100, 0, d.LibEPANET, d.ph); 

% Add the tank node at elevation of 850 ft, initial water levelat 120 ft, minimum level at 100 ft, maximum level at 150 ft and a diameter of 50.5 ft
[index, ~]  = d.apiENaddnode('T1', d.ToolkitConstants.EN_TANK, d.LibEPANET, d.ph);
d.apiENsettankdata(index, 850, 120, 100, 150, 50.5, 0, '', d.LibEPANET, d.ph);
d.apiENsetcoord(index, 0, 60, d.LibEPANET, d.ph); 

% Add the pipes to the project, setting their length, diameter, and roughness values
[index, ~] = d.apiENaddlink('P1', d.ToolkitConstants.EN_PIPE, 'J1', 'J2', d.LibEPANET, d.ph);
d.apiENsetpipedata(index, 10560, 12, 100, 0, d.LibEPANET, d.ph);
[index, ~] = d.apiENaddlink('P2', d.ToolkitConstants.EN_PIPE, 'J1', 'T1', d.LibEPANET, d.ph);
d.apiENsetpipedata(index, 5280, 14, 100, 0, d.LibEPANET, d.ph);
[index, ~]= d.apiENaddlink('P3', d.ToolkitConstants.EN_PIPE, 'J1', 'J3', d.LibEPANET, d.ph);
d.apiENsetpipedata(index, 5280, 14, 100, 0, d.LibEPANET, d.ph);
[index, ~] = d.apiENaddlink('P4', d.ToolkitConstants.EN_PIPE, 'J2', 'J3', d.LibEPANET, d.ph);
d.apiENsetpipedata(index, 5280, 14, 100, 0, d.LibEPANET, d.ph); 

% Add a pump to the project
index = d.apiENaddlink('PUMP', d.ToolkitConstants.EN_PUMP, 'R1', 'J1', d.LibEPANET, d.ph);

% Create a single point head curve (index = 1) and assign it to the pump
errcode = d.apiENaddcurve('C1', d.LibEPANET, d.ph);
d.apiENsetcurvevalue(1, 1, 1500, 250, d.LibEPANET, d.ph);
d.apiENsetlinkvalue(index, d.ToolkitConstants.EN_PUMP_HCURVE, 1, d.LibEPANET, d.ph);

% Save the project for future use
d.apiENsaveinpfile('example2.inp', d.LibEPANET, d.ph);