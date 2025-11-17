function plotahead(lay,channelmappings,data)

a = find(data<-1);
data(a) = -1;

hold on;
for n = 1:4
    plot(lay.outline{n}(:,1),lay.outline{n}(:,2),'k-');
end

for n = 1:64
    if data(n)>0
        plot(lay.pos(channelmappings(n),1),lay.pos(channelmappings(n),2),'ko', 'MarkerSize', 20, 'Color', [0 0 0],'MarkerFaceColor',  [1 1-data(n) 1-data(n)]);
    else
        plot(lay.pos(channelmappings(n),1),lay.pos(channelmappings(n),2),'ko', 'MarkerSize', 20, 'Color', [0 0 0],'MarkerFaceColor',  [1+data(n) 1+data(n) 1]);
    end
    
    text(lay.pos(channelmappings(n),1)-(0.01*length(lay.label{channelmappings(n)})),lay.pos(channelmappings(n),2),lay.label{channelmappings(n)});
end

plot([-0.7 0.7], [0 0], 'k-');
plot([0 0], [-0.7 0.7], 'k-');

axis square;
axis([-0.7 0.7 -0.7 0.7]);

end
