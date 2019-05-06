%wingrock simulation with matched uncertainty

% Using code given by Prof.Girish Chaudhary
% Modified by Vardhan Dongre
clc
close all;
clear all;


%% sim params
t0=0;
tf=5;%170   % 5 Seconds run
dt=0.005;
t=t0:dt:tf;

wn=0.01;% noise covariance


%% initialization

x=[0;3.5];%[3;,6];%
n2=6;
Wstar=[0.8 0.2314 0.6918 -0.6245 0.0095 0.0214]';%[0.2 -0.0186 0.0152 -0.06245 0.0095 -0.0214]';

Wstar_orig=Wstar;
W=Wstar*0+randn(1,6)'*0.0;

Kp = 1.5;                 % proportional gain
Kd = 1.9;                 % derivative gain

A=[0 1;-Kp -Kd];
B = [0; 1];
Q = eye(2);
P = lyap(A',Q);%A' instead of A because need to solve A'P+PA+Q=0
p=0;
[Lp,PP,E] = lqr(A,B,eye(2)*100,1);



%% commands
xref=0;
XREF=zeros(length(t),1);
 XREF(5/dt:15/dt)=0;
 XREF(15/dt:25/dt)=1;
 XREF(35/dt:45/dt)=-1; 

 v_ad=0;

%% plotting array initialization 
index=1;

T_REC        = zeros(length(t),1);
X_REC        = zeros(length(t),1);
XDOT_REC     = zeros(length(t),1);
XERR_REC     = zeros(length(t),1);
XDOTERR_REC  = zeros(length(t),1);
DELTACMD_REC = zeros(length(t),1);%control input
DELTAERR_REC = zeros(length(t),1);

%%
for t=t0:dt:tf

    %compute error
    x_rm(1)=XREF(index); 
    e=x_rm-x;%compute reference model error
    
    %compute PD control
    v_pd=[Kp Kd]*e;
    deltaCmd = v_pd;%Nu
    delta = deltaCmd;
          
    %propagate state
    [x,xDot]=wingrock_sim(x,delta,dt,Wstar);
    %emulate sensor noise
    x=x+randn(2,1)*wn;
  
    %record for plotting
    T_REC(index)        = t;
    X_REC(index)        = x(1);
    XDOT_REC(index)     = x(2);
    XERR_REC(index)     = e(1);
    XDOTERR_REC(index)  = e(2);
    DELTACMD_REC(index) = delta;%control input
    index = index+1;
end

%% plotting


figure(2);
subplot(3,1,1);
plot(T_REC, XERR_REC);
xlabel('time (seconds)');
ylabel('xErr (deg)');
title('Position Error');
grid on;
subplot(3,1,2);
plot(T_REC, XDOTERR_REC);
xlabel('time (seconds)');
ylabel('xDotErr (deg/s)');
title('Angular Rate Error');
grid on;
subplot(3,1,3);
plot(T_REC, DELTACMD_REC);
xlabel('time (seconds)');
ylabel('\delta (deg)');
title('Angular Rate Error');
grid on;

figure(1);
subplot(2,1,1)
plot(T_REC,X_REC);
xlabel('time (seconds)');
ylabel('deg');
title('roll angle');
grid on;

subplot(2,1,2)
plot(T_REC,XDOT_REC);
xlabel('time (seconds)');
ylabel('xDot (deg/s)');
title('roll rate');
grid on;

%% SAVING DATA TO WORKSPACE

filename = 'test.mat';

A = [ ones(length(X_REC),1) X_REC XDOT_REC abs(X_REC).*XDOT_REC abs(XDOT_REC).*XDOT_REC X_REC.^3 ];

for i=1:length(X_REC)
pdot(i)=A(i,:)*Wstar_orig;
end

Xfind=pinv(A)*pdot';

theta=zeros(6,1);

%% Linear regression

iter=20;
alpha=0.01;

J=cost_min(A,pdot',theta);

beta_result=gradientDescent(A, pdot', theta, alpha, iter);

%Plot
figure()
plot(T_REC, A*beta_result)
title('Time History of Predicted vs Exact')
hold on
plot(T_REC,pdot)
legend('Predicted','Exact')
xlabel('Time (s)')
ylabel('PDOT (predicted/Exact)')
hold off
grid on

save test.mat






