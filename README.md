# 改进黑翅鸢算法（IBKA）

**质心边界控制 + 双体加权融合 + 双分布扰动自适应差分变异**

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24069037.svg)](https://doi.org/10.5281/zenodo.24069037)

本仓库是论文《改进黑翅鸢算法》的完整实验代码与结果，包含四个部分：CEC2017 基准函数测试、消融实验、约束工程优化、光伏电池参数辨识。核心改进算法为 `IBKA.m`，其函数签名与原始黑翅鸢算法 `BKA.m` 完全一致，可直接替换调用。

---

## 1. 算法简介

黑翅鸢算法（Black-winged Kite Algorithm, BKA）模拟黑翅鸢的**攻击行为**（Attack）与**迁徙行为**（Migration）。本工作在其框架上引入三项改进，对应函数中的三段代码：

### 改进点 1：质心边界控制（Centroid-based Boundary Handling）

原始 BKA 对越界分量直接截断到边界（`max/min`），会丢失方向信息导致搜索停滞在边界面上。IBKA 将越界分量拉向 **种群质心与边界的中点**：

```
若 x_j > ub_j:  x_j = (Centroid_j + ub_j) / 2
若 x_j < lb_j:  x_j = (Centroid_j + lb_j) / 2
```

其中 `Centroid = mean(XPos, 1)` 为当前种群质心。该处理保留了一定的种群分布信息，使越界个体回到可行域内部而非贴边聚集。改进点在攻击、迁徙、差分变异三处均生效（按分量向量化处理）。

### 改进点 2：双体加权融合策略（Double-body Weighted Fusion）

原始 BKA 迁徙行为中，较优个体的更新方向为 `x_i + C(0,1)·(x_i − x_leader)`，即远离领导者，方向单一。IBKA 改为向"当前个体与随机个体的加权中心"与领导者的连线上搜索：

```
w = rand
x_new = x_i + C(0,1) · ( x_leader − ( w·x_i + (1−w)·x_random ) )
```

权重 `w` 逐个体随机，既保留了向领导者的引导，又引入随机个体的多样性信息，缓解种群同质化。

### 改进点 3：双分布扰动自适应差分变异（Dual-Distribution Adaptive Differential Mutation）

每轮迭代结束后对全种群执行一次贪心选择的差分变异，步长 `c` 由个体到最优解的归一化距离决定，并按黄金比角度做余弦振荡调节：

```
theta   = ((sqrt(5) − 1) · t · pi) / 2
c_i     = R_i · (1 + 0.4·cos(theta)) / (R_max + eps)          R_i = ||x_best − x_i||
p_levy  = (R_i / R_max) · (1 − 0.5 · t / T)                   Levy 概率：远处/前期高
```

按概率 `p_levy` 选择两种重尾分布之一：

| 分支 | 更新式 | 作用 |
| --- | --- | --- |
| Lévy（`rand < p_levy`） | `x_best + r5·c·L(β)·(x_best − x_i) + (1−r5)·c·L(β)·(x_best − x_worst)` | 大跨度跳跃，全局探索 |
| Cauchy（否则） | `x_best + r4·c·Cauchy·(x_r1 − x_r2) + (1−r4)·c·Cauchy·(x_r3 − x_i)` | 重尾局部搜索，精细开发 |

其中 `β = 1.5`，Lévy 步长由 Mantegna 方法生成。远处个体、迭代前期更倾向 Lévy（探索）；靠近最优解或迭代后期更倾向 Cauchy（开发），实现探索与开发的自适应平衡。

### 参数化版本

`CEC2017数值实验/IBKA_p.m` 是 `IBKA.m` 的参数化版本，便于做参数敏感性分析：

```matlab
[f, x, curve] = IBKA_p(pop, T, lb, ub, dim, fobj, beta, amp, rho)
%   beta : Lévy 指数，默认 1.5
%   amp  : 步长振荡幅值，默认 0.4
%   rho  : Levy 概率的迭代衰减系数，默认 0.5
```

取默认值 `(1.5, 0.4, 0.5)` 时，`IBKA_p` 与 `IBKA` 在相同随机种子下结果逐位一致，可用 `test_ibka_p.m` 自行验证。

### 计算开销说明

BKA 每轮迭代消耗 `2·pop` 次函数评估（攻击 + 迁徙），IBKA 额外增加一次全种群差分变异，为 `3·pop` 次，约为 BKA 的 **1.5 倍**。若审稿要求等 FES 对比，可据此折算迭代次数。

---

## 2. 目录结构

```
├── 任务要求.txt
├── README.md
│
├── CEC2017数值实验/                    ← 基准测试（29 个函数，F2 按 CEC 原始定义剔除）
│   ├── IBKA.m                          ★ 核心改进算法
│   ├── IBKA_p.m                        参数化版本（敏感性分析）
│   ├── BKA.m                           原始黑翅鸢算法
│   ├── GGO.m / OOA.m / ZOA.m / DBO.m / AOA.m / WOA.m / RIME.m / SABO.m   对比算法
│   ├── Get_Functions_cec2017.m         CEC2017 目标函数封装（返回 lb/ub/dim/fobj）
│   ├── cec17_func.cpp                   CEC2017 底层实现（C 源码）
│   ├── cec17_func.mexw64                已编译的 Windows 64 位 mex
│   ├── input_data/                     CEC2017 移位/旋转/置换数据（M_*.txt 等）
│   ├── initialization.m                种群初始化
│   ├── func_plot2017.m                 CEC2017 函数三维地形切片绘图（x1–x2 平面，其余维取 0）
│   ├── main1.m                         单函数演示：8 算法最优值 + 地形/收敛曲线对比
│   ├── main2.m                         统计实验：8 算法 × 29 函数 × 30 次 → Excel
│   ├── run_cec2017_curves.m            收敛曲线数据（图 2：每函数单次运行、固定种子）
│   ├── run_seeds.m                     6 个重点函数（F1/F12/F13/F15/F19/F30）10 种子曲线
│   ├── run_v6_cec_all.m                第六版一次性跑完 E1 基准 + E1b 曲线 + E2 敏感性
│   ├── run_v6_cec_rest.m               同上，但跳过 E1，只补 E1b + E2
│   ├── test_ibka_p.m                   IBKA_p 与 IBKA 一致性验证
│   └── *.mat / *.xlsx                  已保存的结果数据与统计表
│
├── 消融实验/                            ← 三个改进点的逐项去除
│   ├── IBKA.m                          完整版（三点全含）
│   ├── IBKA_1.m                        去除改进点 1（边界处理退化为简单截断）
│   ├── IBKA_2.m                        去除改进点 2（迁徙行为恢复原始 BKA）
│   ├── IBKA_3.m                        去除改进点 3（无差分变异阶段）
│   ├── BKA.m
│   ├── main.m                          5 算法 × 29 函数 × 30 次 → Excel 统计/检验结果
│   ├── Get_Functions_cec2017.m / cec17_func.* / input_data/
│   └── 指标结果.xlsx / 秩和检验结果.xlsx / Friedman检验结果.xlsx
│
├── 工程应用/                            ← 三个约束优化问题
│   ├── IBKA.m / BKA.m / RIME.m / SABO.m / GoldSA.m / PSO.m
│   ├── Get_Functions_details.m         F1 焊接梁 / F2 压缩弹簧 / F3 压力容器（罚函数法）
│   ├── main.m                          10 次独立运行 → Results_F1~F3.xlsx
│   ├── run_v6_eng.m                    30 次独立运行 → e3_eng30_v6.mat
│   └── Results_F1.xlsx / Results_F2.xlsx / Results_F3.xlsx
│
└── 光伏电池参数辨识应用/                 ← RTC France 电池的 5 种模型
    ├── IBKA.m / BKA.m / RIME.m / SABO.m / GoldSA.m / PSO.m
    ├── select_PV_model.m               1DM / 2DM / 3DM / 4DM / PMM 模型与目标函数（RMSE）
    ├── Cal_models.m                    由最优参数计算 I-V / P-V 曲线与误差指标
    ├── Cal_stats.m                     多次运行统计（best/worst/mean/std/median）
    ├── cell_data.txt                   单电池实测 I-V 数据（1DM~4DM 使用）
    ├── pvmodule_data.txt               光伏组件实测 I-V 数据（PMM 使用）
    ├── main.m                          5 次运行演示，导出 Excel 与 .fig 图窗
    ├── run_v6_pv.m                     30 次运行 → e4_pv30_v6.mat
    └── *.xlsx / *.fig                  结果统计与曲线
```

四个子目录均自带算法文件与所需依赖，可独立运行；各目录内的 `IBKA.m` 功能一致（仅注释有个别差异），按目录复制是为了避免脚本之间互相依赖。

---

## 3. 运行环境

| 项目 | 要求 |
| --- | --- |
| MATLAB | R2022b 及以上（代码在 R2022b 下开发） |
| 工具箱 | Statistics and Machine Learning Toolbox（`ranksum` / `friedman` / `boxplot`）；Parallel Computing Toolbox（`main2.m`、`消融实验/main.m` 中的 `parfor`，可选） |
| 操作系统 | Windows 64 位（`cec17_func.mexw64` 为预编译文件） |
| Excel | 导出 `.xlsx` 需安装 Microsoft Excel（`xlswrite` / `writetable`） |

> 非 Windows 平台或 MATLAB 版本不兼容时，需在 `CEC2017数值实验/` 目录下重新编译 mex：
> ```matlab
> mex -setup C++
> mex cec17_func.cpp -DWINDOWS
> ```

本机已在 MATLAB R2025b 下验证：`cec17_func.mexw64` 可正常加载；`test_ibka_p.m` 通过（`IBKA_p` 默认参数与 `IBKA` 在 3 个种子下逐位一致）；光伏 1DM 与焊接梁问题的短迭代冒烟测试均可正常运行；`boxplot` / `ranksum` / `friedman` 均可用。

---

## 4. 快速开始

`IBKA` 与 `BKA` 的调用方式完全一致，返回最优适应度、最优解和收敛曲线：

```matlab
[Best_f, Best_x, Convergence_curve] = IBKA(pop, T, lb, ub, dim, fobj);
```

下面按四个实验分别说明。**每个实验都必须把 MATLAB 当前目录切换到对应子文件夹**后再运行脚本（`cec17_func` 通过相对路径 `input_data/...` 读取数据文件）。

### 4.1 CEC2017 基准测试

```matlab
cd CEC2017数值实验
```

| 脚本 | 内容 | 规模 | 用途 |
| --- | --- | --- | --- |
| `main1.m` | 8 算法（IBKA/BKA/GGO/OOA/ZOA/DBO/AOA/WOA）在单个函数上的对比 | 1 函数 × 1 次 | 快速检查、画地形图与收敛曲线 |
| `main2.m` | 同上 8 算法完整统计 + 秩和检验 + Friedman 检验 + 箱型图 | 29 函数 × 30 次 | 论文主表（Excel） |
| `run_cec2017_curves.m` | 每函数单次运行、固定种子，保存全部收敛曲线 | 29 函数 × 8 算法 | 论文图 2 数据 |
| `run_seeds.m` | 重点函数多种子曲线，供挑选代表性运行 | 6 函数 × 8 算法 × 10 种子 | 论文图 2 备选 |
| `run_v6_cec_all.m` | E1 基准重跑 + E1b 曲线补跑 + E2 参数敏感性 | 见下 | 第六版数据（当前论文数据） |
| `run_v6_cec_rest.m` | 跳过 E1，只跑 E1b + E2 | — | 断点续跑 |
| `test_ibka_p.m` | 验证 `IBKA_p` 默认参数与 `IBKA` 完全一致 | 3 个种子 | 正确性自检 |

使用步骤：

1. **验证 mex 可用**（只需一次）：
   ```matlab
   [lb, ub, dim, fobj] = Get_Functions_cec2017(1, 30);
   disp(fobj(zeros(1, 30)))   % 应返回约 1e2 量级的数值，而非报错
   ```
2. **快速看效果**：修改 `main1.m` 顶部 `number`（函数编号）与 `dim`（维度）后运行。
3. **跑论文主表**：直接运行 `main2.m`，结束后自动生成 `指标结果.xlsx`、`秩和检验结果.xlsx`、`Friedman检验结果.xlsx`，并弹出箱型图。
4. **跑第六版数据**：直接运行 `run_v6_cec_all.m`（耗时最长），或若 `e1_best30_v6.mat` 已存在则运行 `run_v6_cec_rest.m` 只补 E1b/E2。

> `main2.m`、`run_v6_cec_all.m` 的完整运行是**小时级**（8 算法 × 29 函数 × 30 次 × 500 迭代）。首次调试建议把 `run` 改为 2~3、`max_iter` 改为 50 先跑通流程。若并行池启动失败，可把 `parfor` 改成 `for`。

### 4.2 消融实验

```matlab
cd 消融实验
main
```

对比 5 个版本：`BKA`（原始）、`IBKA_1`（去改进点 1）、`IBKA_2`（去改进点 2）、`IBKA_3`（去改进点 3）、`IBKA`（完整）。运行结束后生成 `指标结果.xlsx`、`秩和检验结果.xlsx`、`Friedman检验结果.xlsx`（每个文件为 29 函数 × 5 算法的统计/检验结果）。

### 4.3 约束工程优化

```matlab
cd 工程应用
```

- `main.m`：修改顶部 `Function_name`（`'F1'` 焊接梁 / `'F2'` 压缩弹簧 / `'F3'` 压力容器）与 `Run_times` 后运行，输出统计表并保存 `Results_F1.xlsx` 等。
- `run_v6_eng.m`：一次跑完三个问题、6 算法（IBKA/BKA/RIME/SABO/GoldSA/PSO）、30 次独立运行，结果保存为 `e3_eng30_v6.mat`（变量 `BestE` 为 3×6×30 的最优值，`BestX` 为各问题各算法的最优解）。

### 4.4 光伏电池参数辨识

```matlab
cd 光伏电池参数辨识应用
```

- `main.m`：顶部 `pv_type` 可切换 `'1DM'`（单二极管，5 参数）、`'2DM'`（7 参数）、`'3DM'`（9 参数）、`'4DM'`（11 参数）、`'PMM'`（组件模型）。默认 `run_times = 5`、`Max_iter = 100`，运行后生成
  - `[pv_type]-结果统计.xlsx`（3 个 sheet：统计指标 / 最优参数 / I-V 与 P-V 误差指标）
  - `[pv_type]-收敛曲线.fig`、`[pv_type]-I-V曲线.fig`、`[pv_type]-P-V曲线.fig`
- `run_v6_pv.m`：5 种模型 × 6 算法 × 30 次独立运行，保存 `e4_pv30_v6.mat`（`BestPV` 为 5×6×30 的 RMSE，`AllCurves` 为收敛曲线，`BestXs` 为最优参数，`Vm/Im/Io/Po` 为 1DM 最优参数的 I-V/P-V 曲线数据）。

---

## 5. 参数设置

| 实验 | 种群 `pop` | 最大迭代 `T` | 维度 `dim` | 独立运行次数 | 目标函数 |
| --- | --- | --- | --- | --- | --- |
| CEC2017（main1 / main2） | 30 | 500 | 30（可选 2/10/30/50/100） | 1 / 30 | F1~F30（不含 F2） |
| CEC2017（v6 数据） | 30 | 500 | 30 | 30 | E1：8 算法 × 29 函数 |
| 消融实验 | 30 | 500 | 30 | 30 | F1~F30（不含 F2） |
| 工程应用 | 30 | 500 | 4 / 3 / 4 | 10（main）/ 30（v6） | 焊接梁 / 压缩弹簧 / 压力容器 |
| 光伏辨识 | 30 | 100 | 5 / 7 / 9 / 11 / 5 | 5（main）/ 30（v6） | 1DM / 2DM / 3DM / 4DM / PMM |

CEC2017 函数分组（按官方定义）：F1、F3 单峰；F4~F10 简单多峰；F11~F20 混合；F21~F30 复合。所有函数解空间均为 `[-100, 100]^D`。

---

## 6. 已有结果文件（`.mat`）说明

| 文件 | 生成脚本 | 主要变量 |
| --- | --- | --- |
| `curves_cec2017_v5.mat` | `run_cec2017_curves.m` | `Curves` (29×8×500)、`Best` (29×8)、`F`、`algorithms` |
| `curves_seeds_v5.mat` | `run_seeds.m` | `CurvesS` (6×8×10×500)、`BestS` (6×8×10)、`Fkey` |
| `e1_best30_v6.mat` | `run_v6_cec_all.m` | `Best30` (29×8×30)，8 算法：IBKA/BKA/GGO/OOA/ZOA/DBO/RIME/SABO |
| `e1b_curves_rs_v6.mat` | `run_v6_cec_all.m` | `CurvesRS` (29×2×500)、`CurvesRS_S`、`BestRS_S`（RIME/SABO 曲线） |
| `e2_sens_v6.mat` | `run_v6_cec_all.m` | `BestS` (29×7×30)、`settings`（7 组 (beta, amp, rho) 设置） |
| `工程应用/e3_eng30_v6.mat` | `run_v6_eng.m` | `BestE` (3×6×30)、`BestX` (3×6)、`probs`、`algs` |
| `光伏电池参数辨识应用/e4_pv30_v6.mat` | `run_v6_pv.m` | `BestPV` (5×6×30)、`AllCurves`、`MeanCurves`、`BestXs`、`Vm/Im/Io/Po` |

> 仓库中不包含从 `.mat` 重绘论文图的脚本：`CEC2017数值实验/main2.m` 运行时直接绘制箱型图与 Friedman 平均排名图，`消融实验/main.m` 只导出 Excel。如需基于 `.mat` 重新出图，可 `load` 对应文件后按上表变量含义自行绘制（例如 `boxplot(squeeze(Best30(:,1,:))')`）。
> 注意：重复运行 `run_v6_*.m` 会覆盖同名 `.mat` 文件。

E2 敏感性分析的 7 组参数（`settings` 行序）：

| 序号 | beta | amp | rho | 说明 |
| --- | --- | --- | --- | --- |
| 1 | 1.5 | 0.4 | 0.5 | 默认设置 |
| 2 | 1.2 | 0.4 | 0.5 | beta 减小 |
| 3 | 1.8 | 0.4 | 0.5 | beta 增大 |
| 4 | 1.5 | 0.2 | 0.5 | amp 减小 |
| 5 | 1.5 | 0.6 | 0.5 | amp 增大 |
| 6 | 1.5 | 0.4 | 0.3 | rho 减小（后期仍偏探索） |
| 7 | 1.5 | 0.4 | 0.7 | rho 增大（更早转向开发） |

---

## 7. 复现性（随机种子）

所有脚本在运行算法前均显式调用 `rng(seed)`，保证结果可复现：

| 实验 | 种子设置 | 含义 |
| --- | --- | --- |
| E1 基准（v6） | `rng(55500000 + fn*1000 + r)` | 同一 (函数, 运行序号) 下各算法起于同一随机流（公共随机数） |
| 收敛曲线（v5） | `rng(20250000 + fn)` | 同一函数下各算法种子相同 |
| 多种子曲线 | `rng(77000000 + fn*100 + s)` | 每种子每算法同起点 |
| 工程应用（v6） | `rng(77700000 + pp*1000 + r)` | 同一问题同一起点 |
| 光伏辨识（v6） | `rng(66600000 + mi*1000 + r)` | 同一模型同一起点 |
| E2 敏感性 | `rng(55500000 + fn*1000 + r)` | 与 E1 完全对齐，便于逐次对比 |

`main1.m` / `main2.m` / `消融实验/main.m` 未固定种子，每次运行结果会有细微波动；需要严格复现时请自行在算法调用前加 `rng(...)`。

---

## 8. 常见问题

**Q1：运行 CEC2017 相关脚本报错找不到 `input_data\M_1_D30.txt`**
未把当前目录切到 `CEC2017数值实验/`（或 `消融实验/`）。`cec17_func` 用相对路径读取数据，必须先 `cd` 到含 `input_data` 的目录。

**Q2：提示 `cec17_func` 无效 MEX 文件**
`cec17_func.mexw64` 仅适用于 Windows 64 位 MATLAB。请在本机重新编译：在该目录下执行 `mex -setup C++` 后 `mex cec17_func.cpp -DWINDOWS`。

**Q3：`parfor` 报错或并行池无法启动**
`main2.m` 与 `消融实验/main.m` 使用 `parfor`。没有 Parallel Computing Toolbox 时，把 `parfor` 改为 `for`；也可先删除 `parpool('local')` 那段代码。

**Q4：`xlswrite` 报错**
`xlswrite` 需要本机安装 Excel。若环境没有 Excel，可改用 `writetable` / `writecell`（`main2.m` 与工程应用脚本已使用 `writetable`/`writecell`）。

**Q5：为什么没有 F2？**
CEC2017 官方在统计时剔除 F2（单峰函数组只保留 F1 与 F3），因此所有脚本的 `F` 列表均为 `[1 3 4 ... 30]`。测试时请不要把 `main1.m` 的 `number` 设为 2，也不要把 F2 加入对比表。

**Q6：结果与论文小数点后几位有差异？**
差异来自随机种子与机器浮点环境。论文数据由第 6 版脚本（`run_v6_*.m`）在固定种子下生成，复现时请使用相同的脚本与种子设置。

---

## 9. 参考文献

本仓库**不再分发**下列文献的原文 PDF（版权归各期刊出版单位所有），请通过期刊官网或 DOI 获取：

- Wang J, Wang W C, Hu X X, et al. Black-winged kite algorithm: a nature-inspired meta-heuristic for solving benchmark functions and engineering problems[J]. Artificial Intelligence Review, 2024, 57: 98. DOI: 10.1007/s10462-024-10723-4
- 高跃庭, 桂方志, 王欢, 等. 基于多策略改进鲸鱼算法的多无人机协同路径规划[J/OL]. 控制与决策, 2026. DOI: 10.13195/j.kzyjc.2025.0929
- 汪家伟, 付盛伟, 黄海松. 改进霜冰优化算法用于无人机三维路径规划[J]. 电子测量技术, 2025, 48(9): 44-55. DOI: 10.19651/j.cnki.emt.2417162
- 郑修斌, 陈珺. 基于蜣螂优化算法的光伏电池参数辨识[J]. 广西师范大学学报(自然科学版), 2024, 42(4): 51-63. DOI: 10.16088/j.issn.1001-6600.2023091602
- 吴艳娟, 刘振朝, 王云亮. 基于 IPOA 的太阳电池模型参数辨识[J]. 太阳能学报, 2024, 45(1): 1-10. DOI: 10.19912/j.0254-0096.tynxb.2022-1416
- 欧阳城添, 黄祖威, 刘裕嘉, 等. 基于 RCJAYA 算法的太阳电池参数辨识[J]. 北京航空航天大学学报, 2024, 50(7): 2133-2140. DOI: 10.13700/j.bh.1001-5965.2022.0576

---

## 10. 引用（Citation）

项目已由 Zenodo 归档，可通过 DOI 永久访问：

- 版本 DOI（最新 v1.0.1）：[10.5281/zenodo.24077356](https://doi.org/10.5281/zenodo.24077356)
- 概念 DOI（始终指向最新版本）：[10.5281/zenodo.24069036](https://doi.org/10.5281/zenodo.24069036)

如果本项目的代码或结果对你的研究有帮助，请引用：

> ecirtpew. (2026). 改进黑翅鸢算法（IBKA）：质心边界控制 + 双体加权融合 + 双分布扰动自适应差分变异 (v1.0.1). Zenodo. https://doi.org/10.5281/zenodo.24077356

BibTeX：

```bibtex
@software{ibka_2026,
  author    = {ecirtpew},
  title     = {改进黑翅鸢算法（IBKA）：质心边界控制 + 双体加权融合 + 双分布扰动自适应差分变异},
  month     = nov,
  year      = 2026,
  publisher = {Zenodo},
  version   = {v1.0.1},
  doi       = {10.5281/zenodo.24077356},
  url       = {https://doi.org/10.5281/zenodo.24077356}
}
```
