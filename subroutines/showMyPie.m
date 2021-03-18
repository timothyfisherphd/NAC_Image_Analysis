% Author:  Jakob Nikolas Kather 

function showMyPie(myLabelCats,CatNames,savepath)
    sums = sum(myLabelCats');
    figure();
    for i = 1:numel(CatNames)
        newLabel{i} = [char(CatNames{i}),10,'N=',num2str(sums(i)),''];
    end
    pie(sums,newLabel); % show pie chart, then plot decorations and save file
    legend('Location','best')
    set(gcf,'Color','w');   
    print(gcf,'-dpng','-r600',savepath);
end