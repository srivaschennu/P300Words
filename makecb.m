function makecb(limits)

figure;
figpos = get(gcf,'Position');
figpos(4) = figpos(3);
figpos(4) = round(figpos(4)/2);
set(gcf,'Position',figpos);

axespos = get(gca,'Position');
axespos(3) = axespos(3)-0.1;
set(gca,'Visible','off','Position',axespos);
caxis(limits);
cb_h = colorbar('FontSize',26,'FontName','Helvetica');
cb_labels = num2cell(get(cb_h,'YTickLabel'),2);
cb_labels{1} = [cb_labels{1} ' pA.m'];
set(cb_h,'YTickLabel',cb_labels);

set(gcf,'Color','white','FileName','figures/colorbar','Name','colorbar');
export_fig(gcf,[get(gcf,'FileName') '.eps']);