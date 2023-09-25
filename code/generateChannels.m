function [Hdir,H1,H2] = generateChannels(Nt,Nr,Nris,lt,lr,D,no_mat,K,f,dist_ris,varargin)
% Hdir : direct link
% H1: Tx to RIS
% H2: RIS to Rx

lambda = 3e8/f;     % wavelength
dt = lambda/2;      % TX antenna space
dr = lambda/2;      % RX antenna space
dris = lambda/2;    % RIS element space
k = 2*pi/lambda;    % wavenumber

% geometrical placement
% x, y and z axis 
% TX array
tx_arr = zeros(1,Nt); 
tx_arr(2,:) = (sort(0:Nt-1,'descend')-(Nt-1)/2)*dt+lt; 
tx_arr(3,:) = zeros(1,Nt); 
% RX array
rx_arr(1,:) = D*ones(1,Nr);
rx_arr(2,:) = (sort(0:Nr-1,'descend')-(Nr-1)/2)*dr+lr; 
rx_arr(3,:) = zeros(1,Nr);
% RIS
center = [dist_ris 0]; % RIS center position 
N1 = sqrt(Nris);
N2 = N1;
ris_pos = RISPosition(N1,N2,dris,center); % RIS elements coordinates 
a = repmat(ris_pos{1},N1,1);   % placing RIS elements in proper coordinates
ris_arr(1,:) = a(:)';        
ris_arr(2,:) = zeros(1,Nris);
ris_arr(3,:) = repmat(ris_pos{2},1,N2); 

if isempty(varargin)
    alpha = 1;
else
    alpha = varargin{1};
end

% direct TX-RX paths/channel matrix
for i1 = 1:Nr
    for j1 = 1:Nt
        d(i1,j1) = norm(rx_arr(:,i1)-tx_arr(:,j1));
    end 
end
Hdir_los = exp(-1i*k*d);
tx_rx_dist = sqrt(D^2+(lt-lr)^2);
FSPL_dir = (lambda/(4*pi))^2/tx_rx_dist^alpha(1);
Hdir = Rician(Hdir_los,sqrt(FSPL_dir),no_mat,K);


% indirect paths (TX-RIS-RX)
for l1 = 1:Nris
    for r1 = 1:Nr  
        d2(r1,l1) = norm(rx_arr(:,r1)-ris_arr(:,l1)); 
    end
    for t1 = 1:Nt
        d1(l1,t1) = norm(tx_arr(:,t1)-ris_arr(:,l1));   
    end
end

tx_ris_dist = sqrt(dist_ris^2+lt^2);
ris_rx_dist = sqrt((D-dist_ris)^2+lr^2);

FSPLindir = lambda^4/(256*pi^2)*...
           ((lt/tx_ris_dist+lr/ris_rx_dist)^2)*...
           1/(tx_ris_dist*ris_rx_dist)^2;
%        FSPLindir = 1;
% TX-RIS
H1_los = exp(-1i*k*d1);
FSPL_1 = sqrt(FSPLindir);
H1 = Rician(H1_los,FSPL_1,no_mat,K);
% RIS-RX
H2_los = exp(-1i*k*d2);
FSPL_2 = 1;
H2 = Rician(H2_los,FSPL_2,no_mat,K);
end

function pos = RISPosition(N1,N2,dist,center)
d1 = (0:N1-1)-(N1-1)/2;
d2 = (0:N2-1)-(N2-1)/2;
pos{1} = center(1)+d1*dist;
pos{2} = center(2)+d2*dist;
end 

function Hout = Rician(Hlos,FSPL,no_mat,K)
Hlos = repmat(Hlos,no_mat,1);
Hnlos = sqrt(1/2)*(randn(size(Hlos))+1i*randn(size(Hlos)));
Htot = FSPL/sqrt(K+1)*(Hlos*sqrt(K)+Hnlos);
dim = size(Hlos,1)/no_mat;
for ind = 1:no_mat
   Hout{ind} = Htot((ind-1)*dim+1:ind*dim,:); 
end
end