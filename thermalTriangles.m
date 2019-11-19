clearvars
close all

eval('CircleHolemesh01')
tempCircle= 50;
tempTopBot= 10;

numNodes= size(nodes,1);
numElem= size(elem,1);

numbering= 0; %= 1 shows nodes and element numbering
plotElements(nodes,elem,numbering)

%Select Boundary points
indT= find(nodes(:,2) > 0.99); %indices of the nodes at the top boundary
indB= find(nodes(:,2) < -0.99);%indices of the nodes at the bottom boundary
indC= find(sqrt(nodes(:,1).^2 + nodes(:,2).^2) < 0.501); %id.on the circle

hold on
plot(nodes(indT,1),nodes(indT,2),'ok','lineWidth',1,'markerFaceColor',...
    'red','markerSize',5)
plot(nodes(indB,1),nodes(indB,2),'ok','lineWidth',1,'markerFaceColor',...
    'red','markerSize',5)
plot(nodes(indC,1),nodes(indC,2),'ok','lineWidth',1,'markerFaceColor',...
    'green','markerSize',5)
hold off

%Define the coefficients vector of the model equation
a11=1;
a12=0;
a21=a12;
a22=a11;
a00=0;
f=0;
coeff=[a11,a12,a21,a22,a00,f];

%Compute the global stiff matrix
K=zeros(numNodes);    %global stiff matrix
F=zeros(numNodes,1);  %global internal forces vector
Q=zeros(numNodes,1);  %global secondary variables vector

for e = 1:numElem
    [Ke, Fe] = linearTriangElement(coeff,nodes,elem,e);
    rows= [elem(e,1); elem(e,2); elem(e,3)];
    cols= rows;
    K(rows,cols)= K(rows,cols)+Ke;
    if (coeff(6) ~= 0)
        F(rows)= F(rows) + Fe;
    end
end

%Booundary Conditions
fixedNodes= [indT', indB', indC'];         %fixed Nodes (global numbering)
freeNodes= setdiff(1:numNodes,fixedNodes); %free Nodes (global numbering)

% Essential B.C.
u=zeros(numNodes,1);
u(indT)= tempTopBot;
u(indB)= tempTopBot;
u(indC)= tempCircle;

%Natural B.C:
Q(freeNodes)=0.0; !all them are zero

%Reduced system
Fm = F(freeNodes) + Q(freeNodes) - K(freeNodes,fixedNodes)*u(fixedNodes);
Km = K(freeNodes,freeNodes);

%Compute the solution
um = Km\Fm;
u(freeNodes)= um;

%PostProcess: Compute secondary variables and plot results
Q = K*u - F;
titol='Temperature Distribution';
colorScale='jet';
plotContourSolution(nodes,elem,u,titol,colorScale);


%Exercise 1:
%Compute the temperature for the point p=[0.5, 0.8].
p= [0.5, 0.8];

for e=1:numElem
    vertexs= nodes(elem(e,:),:);
    [alphas,isInside] = baryCoord(vertexs,p);
    if (isInside > 0)
        pElem = e;
        numNodElem= elem(e,:);
        break;
    end
end

tempP = alphas*u(numNodElem);
fprintf('Point P = (%.1f,%.1f) belongs to element number: %d\n',p,pElem)
fprintf('Number of nodes of elem %d: %d, %d, %d\n',pElem,numNodElem)
fprintf('Interpolated temperature at point P: %.4e\n',tempP)
