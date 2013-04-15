function makecb(limits)

figure;
% figpos = get(gcf,'Position');
% figpos(3) = round(figpos(3)*(0.8));
% set(gcf,'Position',figpos);

axespos = get(gca,'Position');
axespos(3) = axespos(3)-0.1;
set(gca,'Visible','off','Position',axespos);
caxis(limits);
cb_h = colorbar('SouthOutside');
set(cb_h,'FontSize',30,'FontName','Helvetica');

cb_labels = num2cell(get(cb_h,'XTickLabel'),2);
cb_labels{1} = [cb_labels{1} 'pA.m'];
set(cb_h,'XTickLabel',cb_labels);


set(gcf,'Color','white','FileName','figures/colorbar','Name','colorbar');
addpath('/Users/chennu/MATLAB/export_fig/');
export_fig(gcf,[get(gcf,'FileName') '.eps']);