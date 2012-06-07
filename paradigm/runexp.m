function runexp

if ~exist('subjid.txt','file')
    error('subjid.txt not found!');
end

subjid = dlmread('subjid.txt','');

subjid = subjid + 1;

if rem(subjid,2) == 0
    blockorder = [2 1];
else
    blockorder = [1 2];
end

fprintf('\nRunning subject %d with blockorder [%s].\n\n',subjid,num2str(blockorder));

p300words('param_practice.mat',blockorder(1));
clear global hd
uiwait(msgbox('Press OK to continue.'));

p300words('param.mat',blockorder(1));
clear global hd
uiwait(msgbox('Press OK to continue.'));

p300words('param_practice.mat',blockorder(2));
clear global hd
uiwait(msgbox('Press OK to continue.'));

p300words('param.mat',blockorder(2));
clear global hd

dlmwrite('subjid.txt',subjid,'');

