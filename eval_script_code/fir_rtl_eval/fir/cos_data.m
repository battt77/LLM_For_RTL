clear all;close all;clc;
%=======================================================
% generating a cos wave data with txt hex format
%=======================================================
%% 
fc          = 0.25e6 ;
fn          = 7.5e6 ;
Fs          = 50e6 ;
T           = 1/fc ;
Num         = Fs * T ;
t           = (0:Num-1)/Fs ;
cosx        = cos(2*pi*fc*t) ;
cosn        = cos(2*pi*fn*t) ;
cosy        = mapminmax(cosx + cosn) ;
cosy_dig    = floor((2^11-1) * cosy + 2^11) ;
fid         = fopen('cosx0p25m7p5m12bit.txt', 'wt') ;
fprintf(fid, '%x\n', cosy_dig) ;
fclose(fid) ;

% ±”Ú≤®–Œ
figure(1)
subplot(121);plot(t,cosx);
hold on ; plot(t,cosn) ;
subplot(122);plot(t,cosy_dig) ;

%∆µ”Ú≤®–Œ
fft_cosy    = fftshift(fft(cosy, Num)) ;
f_axis      = (-Num/2 : Num/2 - 1) * (Fs/Num) ;
figure(5) ;
plot(f_axis, abs(fft_cosy)) ;


% coef * 2^11 


