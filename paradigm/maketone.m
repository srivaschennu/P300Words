function y = maketone(fs,fc,len)

sf = 1.1; %downscale factor

Ts = 1/fs;                     % sampling period
t = 0:Ts:len-Ts;               % time vector

y = zeros(length(t),1);
y(:) = cos(2*pi*fc*t);
y = y ./ (max(abs(y)) * sf);