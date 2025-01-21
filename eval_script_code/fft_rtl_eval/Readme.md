# fft_rtl_eval

### 简介

使用基于python编写的脚本，评估python**标准fft函数**和由verilog编写的**4通道fft电路和8通道fft**电路的**MSE**误差

其中：

- 4通道fft电路参考自git库：[https://github.com/u3oR/fft_verilog](https://github.com/u3oR/fft_verilog)
- 8通道fft电路参考自菜鸟教程的文章<Verilog 教程 7.5 Verilog FFT 设计>：[https://www.runoob.com/w3cnote/verilog-fft.html](https://www.runoob.com/w3cnote/verilog-fft.html)

开源于：[https://github.com/battt77/fft_rtl_eval](https://github.com/battt77/fft_rtl_eval)

本工程运行需要安装iverilog工具与gtkwave波形查看工具（不看波形可不装）

------

### RTL代码编译：

#### RTL文件：

- fft4文件夹为4通道fft电路代码
- fft8文件夹为8通道fft电路代码

#### RTL编译查看波形：

**所有命令基于fft_rtl_eval根目录运行**

**ff4代码**编译：

```powershell
cd fft4
#编译代码，生成执行文件
iverilog -o fft4_sim fft4_tb.v fft4.v butterfly.v	
#生成波形
vvp ./fft4_sim
#查看波形
gtkwave ./fft4_tb.vcd
```

**fft8代码**编译：

```powershell
cd fft8
#编译代码，生成执行文件
iverilog -o fft8_sim fft8_tb.sv fft8.v butterfly.v	
#生成波形文件
vvp ./fft8_sim
#查看波形
gtkwave ./fft8.vcd
```

------

### Python脚本玩法

评估脚本为**fft_eval.py**

Python需要安装**scipy**包运行fft函数：

```powershell
#安装
pip install scipy
#若有uv工具
uv pip install scipy
```

#### 运行示例：

使用下列命令运行fft_eval脚本评估8通道fft电路：

```powershell
python fft_eval.py --fft_channels 8 --in_bitwidths 24 --out_bitwidths 24 --VCD_dir ./fft8/fft8.vcd
```

参数解析：

- python：当前运行环境的python命令
- fft_channels：FFT 总通道数
- in_bitwidths：单个数据输入位宽
- out_bitwidths：单个数据输出位宽
- VCD_dir：VCD文件路径

同样可使用下列命令运行fft_eval脚本评估4通道fft电路：

```powershell
python fft_eval.py --fft_channels 4 --in_bitwidths 8 --out_bitwidths 10 --VCD_dir ./fft4/fft4_tb.vcd
```

------

### RTL代码规范

为了能够正常运行评估脚本，要求RTL代码具有一定的规范：

- fft电路**实数输入**端口命名规则：

  ```python
  x{$channel_index}_real #$channel_index为channel索引，如第一端口:x0_real，第二端口：x1_real ...
  ```

- fft电路**虚数输入**端口命名规则：

  ```python
  x{$channel_index}_imag #$channel_index为channel索引，如第一端口:x0_imag，第二端口：x1_imag ...
  ```

- fft电路**实数输出**端口命名规则：

  ```python
  y{$channel_index}_real #$channel_index为channel索引，如第一端口:y0_real，第二端口：y1_real ... 
  ```

- fft电路**虚数输出**端口命名规则：

  ```python
  y{$channel_index}_imag #$channel_index为channel索引，如第一端口:y0_imag，第二端口：y1_imag ...
  ```

- 输出数据高电平有效位命名规范为：**yout_valid**，表示输出结果有效，建议**yout_valid**在数据有效**当前时刻置1**或者**提前一个clk置1**

**不规范的代码将导致脚本无法使用**

------

### 注：

- 正常MSE值小于**1**，RTL代码近似度高
- 多做测试，有bug再修吧
- 若运行不成功，请先查看RTL代码端口命名是否正确，输出波形是否正常（无x，z），再考虑是脚本的bug
- 8通道fft电路代码已完成重要勘误：

​	![image-20241030204621259](./image/image-20241030204621259.png)

---

### 维护记录：

2024.11.6：将代码规范中的valid改为yout_valid，避免子模块存在同名端口导致数据有效时刻抓取错误
