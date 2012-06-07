function loadpaths

[~, hostname] = system('hostname');

if strncmpi(hostname,'hsbpc58',length('hsbpc58'))
    assignin('caller','filepath','/Users/chennu/Data/P300Words/');
    assignin('caller','chanlocpath','/Users/chennu/EGI/');
elseif strncmpi(hostname,'hsbpc57',length('hsbpc57'))
    assignin('caller','filepath','D:\Data\P300Words\');
    assignin('caller','chanlocpath','D:\EGI\');
else
    assignin('caller','filepath','');
    assignin('caller','chanlocpath','');
end