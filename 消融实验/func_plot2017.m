function func_plot2017(func_name,dim)
[~,~,dim,fobj]=Get_Functions_cec2017(func_name,dim);
x=-100:2:100;y=x;   %x的范围在[-100,100]
L=length(x);
f=0;
for i=1:L
    for j=1:L
        if dim==2
            f(i,j)=fobj([x(i),y(j)]);
        else
            f(i,j)=fobj([x(i),y(j),zeros(1,dim-2)]);
        end
    end
end
surfc(x,y,f,'LineStyle','none');
title(['CEC2017-F',num2str(func_name)])
xlabel('x 1');
ylabel('x 2');
zlabel('F(x_1,x 2)')
set(gca,'color','none')
grid on
box on
end