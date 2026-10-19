close all
clear
warning('off','MATLAB:illConditionedMatrix')
warning('off','MATLAB:nearlySingularMatrix')

%Melt composition
%[SiO2 TiO2 Al2O3 FeO(T) MnO MgO CaO Na2O K2O P2O5 H2O F2O-1]
Krafla = [75.17 0.22 12.02 3.13 0.11 0.09 1.66 4.58 2.88 0 0.12 0];
Composition = Krafla;  
H2Ot_0 = 0.12; %initial water concentration (wt. %)

%Dynamics geometry
Geometry = 'Radial'; 
BC = 'No stress';
BC_type = 'Dirichlet';
BC_T = 1006+273.15;
flux = 0;

%Material properties
SolModel = 'Liu 2005';
DiffModel = 'Zhang 2010 Metaluminous';
ViscModel = 'Hess and Dingwell 1996';

%Model options
EOSModel = 'Pitzer and Sterner';

%Thermal properties
CpModel = 'BagdassarovDingwell1994';
CpmeltModel = 'Stebbins';
kModel = 'Bruggeman';
kmeltModel = 'BagdassarovDingwell1994';
rhoModel = 'BagdassarovDingwell1994';
alpha = 0;

% Outgassing options
PermModel = 'None';
OutgasModel = 'Diffusive';

%Constants used for calculations
SurfTens = 0.22; % Value for surface tension (N/m)
melt_rho = 2400; % Melt density in kg/m^3
rock_rho = 2400; % Country rock density in kg/m^3
melt_beta = 2.6e-11; % Malfait et al. (2011)
etar = 1; % Relative suspension viscosity from crystals

%Spatial parameters
Nb_0 = 3.86e10; %Bubble number density (number per m^3)
R_0 = 1e-5; %R_0 (m) set independently
phi_0 = (4/3).*pi()*R_0.^3./(1/Nb_0);

% P-T pathway 
P_0 = 101e3; % Initial surface pressure
P_f = 101e3; % Final surface pressure
dPdt = 1e-10;
T_0 = 1006 + 273.15; %Initial temperature in K
T_f = 1006 + 273.15;
dTdt = [10/60 -10/60];
t_quench = 6*60*60;
PTtModel = 'Ramp';
Buoyancy = 'False';
Pp = 0.1*P_0; % 10% Partial pressure water
tf =  6*60*60;
solve_T = true;

% Discretization
nt =10;
n_magma = 10;
t_min = 10;
t_max = 600;

radii= (0.1:0.1:1.6)*1e-3;

resolution = 60; %s
tn = 0:resolution:21600;

for i = 1:length(radii)
    radius = radii(i);
    z_int0 = radii(i);
    [u, phi, rho, drhodt, melt_visc, eta, P, H2O, xH2O, R, Nb, T, Cc, pb,...
    m_loss, zz_p, zz_u, zz_t, t] = main(Composition, H2Ot_0,...
         Geometry, radius, z_int0, ...
    BC, BC_type, BC_T, flux, SolModel, DiffModel, ViscModel, EOSModel, ...
    CpModel, CpmeltModel, kModel, kmeltModel, rhoModel,...
    PermModel, OutgasModel, Pp, SurfTens, melt_rho,...
    rock_rho, alpha, melt_beta, etar, Nb_0, R_0,...
    P_0, P_f, dPdt, T_0, T_f, dTdt, t_quench, PTtModel, Buoyancy, tf,...
    solve_T, t_min, t_max, nt, n_magma);


    % Weighted average of vesicularity for each fragment radius
    % one value for one radius
     Vt = 0 ;
     VPhi = 0 ;
     phi_avg = zeros(1, length(t));

    for j = 1:size(phi, 1) %time 

        for a = 1:size(phi, 2) 
            Vt = Vt + 4/3.*pi().*(zz_u(j, a+1).^3 - zz_u(j, a).^3) ; 
            VPhi = VPhi + 4/3.*pi().*(zz_u(j, a+1).^3 - zz_u(j, a).^3) * phi(j, a) ; 
        end 

        phi_avg(j) = VPhi / Vt ;   

    end 
   
    phi_avg_tn(i, :) = interp1(t, phi_avg, tn,'linear'); % interpolate to 
    % constant time steps

    writematrix(phi_avg_tn, 'phi_grainsizes.xlsx') ;

    dat = struct('Composition',Composition, 'H2Ot_0',H2Ot_0, ...
    'Geometry',Geometry, 'radius',radius, 'z_int0',z_int0, ...
    'BC',BC, 'BC_type',BC_type, 'BC_T',BC_T, 'flux', flux, ...
    'SolModel',SolModel, 'DiffModel',DiffModel, 'ViscModel',ViscModel, ...
    'EOSModel',EOSModel, 'CpMpdel',CpModel, 'CpmeltModel',CpmeltModel, ...
    'kModel',kModel, 'kmeltModel',kmeltModel, 'rhoModel',rhoModel,...
    'PermModel',PermModel, 'OutgasModel',OutgasModel, 'Pp',Pp, ...
    'SurfTens',SurfTens, 'melt_rho',melt_rho, 'rock_rho',rock_rho, ...
    'alpha',alpha, 'melt_beta',melt_beta, 'etar',etar, 'Nb_0',Nb_0, ...
    'R_0',R_0, 'P_0',P_0, 'P_f',P_f, 'dPdt',dPdt, 'T_0',T_0, 'T_f',T_f, ...
    'dTdt',dTdt, 't_quench',t_quench, 'PTtModel',PTtModel, ...
    'Buoyancy',Buoyancy, 'tf',tf, 'solveT',solve_T, 't_min',t_min, ...
    't_max',t_max, 'nt',nt, 'n_magma',n_magma, ...
    'u',u, 'phi',phi, 'rho',rho, 'drhodt',drhodt, 'melt_visc',melt_visc, ...
    'eta',eta, 'P',P, 'H2O',H2O, 'xH2O',xH2O, 'R',R, 'Nb',Nb, 'T',T, ...
    'Cc',Cc, 'pb',pb, 'm_loss',m_loss, 'zz_p',zz_p, 'zz_u',zz_u, ...
    'zz_t',zz_t, 't',t);
    save(['./Results/Radius' num2str(radius*1e-6,'%.0f') '.mat'],'dat')

end

cmap = hot(2*length(t));

t_unit = 's';
if contains(t_unit,'s')
    t_stretch = 1;
elseif contains(t_unit,'min')
    t_stretch = 60;
elseif contains(t_unit,'hr')
    t_stretch = 60*60;
elseif contains(t_unit,'days')
    t_stretch = 60*60*24;
end

f1 = figure(1);
f1.Position = [400,100,600,700];
ax1 = create_axes(4,'vertical');
set(gcf,'color','w');

labels = {'\phi','\Delta Pressure (Pa)','Velocity (m/s)','Temperature (^oC)'};
linewidth = 2;
ys = {phi,P-101e3,u,T-273};
xs = {zz_p,zz_p,zz_u,zz_t};

for i=1:max([1, floor(length(t)/10)]):length(t)
    for j = 1:4
        set(f1,'CurrentAxes',ax1(j))
        hold on;
        h1 = plot(xs{j}(i,:),ys{j}(i,:),'color',cmap(i,:),'linewidth',linewidth);

        ylabel(labels(j))
        box('on')
    end
    xlabel('Radius (m)')
    for j=1:3
        set(f1,'CurrentAxes',ax1(j))
        xticklabels([])
    end
end


