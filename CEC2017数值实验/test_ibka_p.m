%% 一致性验证: IBKA_p(默认参数) 必须与 IBKA 完全一致
clear; clc;
addpath(genpath(pwd));
[lb,ub,~,fhd] = Get_Functions_cec2017(1, 30);
ok = true;
for sd = [1, 42, 2026]
    rng(sd); [f1,~,c1] = IBKA(30, 300, lb, ub, 30, fhd);
    rng(sd); [f2,~,c2] = IBKA_p(30, 300, lb, ub, 30, fhd, 1.5, 0.4, 0.5);
    same = (f1==f2) && isequal(c1,c2);
    fprintf('seed=%d: IBKA=%.6e IBKA_p=%.6e 一致=%d\n', sd, f1, f2, same);
    ok = ok && same;
end
if ok, disp('VERIFIED: IBKA_p(默认值)与IBKA完全一致'); else, error('不一致,需检查'); end
