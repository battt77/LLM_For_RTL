import re 
import numpy as np
from scipy.signal import lfilter
import argparse

def read_vcd(filename):
    signals = {}
    timestamps = []
    current_time = 0
    
    with open(filename, 'r') as file:
        for line in file:
            line = line.strip()
            
            # 解析信号声明
            if line.startswith('$var'):
                parts = line.split()
                signal_type = parts[1]    # 例如 wire, reg 等
                signal_id = parts[3]      # 唯一标识符
                signal_name = parts[4]    # 信号名称
                signals[signal_id] = {'name': signal_name, 'type': signal_type, 'changes': []}
            
            # 解析时间戳
            elif line.startswith('#'):
                current_time = int(line[1:])
                timestamps.append(current_time)
            
            # 解析信号值变化 (二进制值变化)
            elif re.match(r'^[01]', line):
                value = line[0]
                signal_id = line[1:]
                if signal_id in signals:
                    signals[signal_id]['changes'].append((current_time, value))
            
            # 解析信号值变化 (多位二进制或十六进制)
            elif re.match(r'^[b|B|h|H]', line):
                parts = line.split()
                value = parts[0][1:]  # 获取值 (去掉前导字符)
                signal_id = parts[1]
                if signal_id in signals:
                    signals[signal_id]['changes'].append((current_time, value))

    return signals, timestamps
def print_waveform_details(signals):
    print("Waveform Details:\n")
    for signal_id, signal in signals.items():
        print(f"Signal ID: {signal_id}")
        print(f"  Name: {signal['name']}")
        print(f"  Type: {signal['type']}")
        print("  Changes:")
        for change in signal['changes']:
            time, value = change
            print(f"    Time: {time}, Value: {value}")
        print("")

def complex_MSE(x,x_ref):
    return np.mean(np.abs(x-x_ref)**2)

def signed_bin_to_dec(bin_str,bitwidths):
    # 将二进制字符串转换为整数
    value = int(bin_str, 2)
    
    if value & (1 << (bitwidths - 1)):
        value -= (1 << bitwidths)
    
    return value

def fir_eval(h_coe=None,in_bitwidths = 16,out_bitwidths = 32,VCD_dir=None,signinter=False):

    in_name = "xin"
    out_name = "yout"
    signals, timestamps=read_vcd(VCD_dir)

    check_port_name = []
    for signal_id, signal in signals.items():
        check_port_name.append(signal['name'])
    
    assert in_name in check_port_name ,"Make sure your input port name is xin!"
    assert out_name in check_port_name ,"Make sure your output port name is yout!"  
    assert 'clk' in check_port_name,"Make sure your clock name is clk!"
    assert 'xin_en' in check_port_name,"Make sure you have xin_en signal!"      
    assert 'yout_valid'in check_port_name,"Make sure you have yout_valid signal!"    

    valid_time = 0
    en_time = 0
    #数据准备for
    for signal_id, signal in signals.items():
        # #提取clk时钟
        if signal['name'] == 'clk':
            clk_period = signal['changes'][4][0]-signal['changes'][2][0]
        
        #提取en值为高的时刻
        if signal['name'] == "xin_en":
            for change in signal['changes']:
                time, value = change
                if(value == '1'):
                    if en_time<int(time):
                        en_time = int(time)        

        #提取valid值为高的时刻
        if signal['name'] == 'yout_valid':
            for change in signal['changes']:
                time, value = change
                if(value == '1'):
                    if valid_time<int(time):
                        valid_time = int(time)

    in_time_last = en_time
    out_time_last = valid_time
    for signal_id, signal in signals.items(): 

        if signal['name'] == in_name:
            spilt_in=[]
            #根据Valid统计除X值以外有效y的个数
            for change in signal['changes']:
                time , value = change
                if(int(time) >= en_time):
                    if int(time) - in_time_last <= clk_period:
                        spilt_in.append(value)
                        in_time_last = int(time)
                    else:
                        #补齐相同的输入
                        for i in range(int((int(time)-in_time_last)/clk_period)-1):
                            spilt_in.append(spilt_in[-1])
                        spilt_in.append(value)
                        in_time_last = int(time)
            xin_len= len(spilt_in)        

        if signal['name'] == out_name:
            spilt_out=[]
            #根据Valid统计除X值以外有效y的个数
            for change in signal['changes']:
                time , value = change
                if(int(time) > valid_time):
                    if int(time) - out_time_last <= clk_period:
                        spilt_out.append(value)
                        out_time_last = int(time)
                    else:
                        #补齐相同的输出
                        for i in range(int((int(time)-out_time_last)/clk_period)-1):
                            spilt_out.append(spilt_out[-1])
                        spilt_out.append(value)
                        out_time_last = int(time)
            yout_len= len(spilt_out)
            
    if(xin_len > yout_len):
        xin_len = yout_len
    assert xin_len==yout_len,"The amout of Input  and Output is different!"

    in_array = np.empty(xin_len)
    out_array = np.empty(yout_len)

    for signal_id, signal in signals.items():     
        # 寻找输入值
        if signal['name'] == in_name:
            for i in range(xin_len):
                value = spilt_in[i]
                if(signinter):
                    in_array[i]=signed_bin_to_dec(value,in_bitwidths)
                else:
                    in_array[i]=int(value,2)
            
        # 寻找输出结果
        if signal['name'] == out_name:
            #循环提取
            for i in range(yout_len):
                value = spilt_out[i]
                if signinter :
                    out_array[i]=signed_bin_to_dec(value,out_bitwidths)
                else:
                    out_array[i]=int(value,2)

    #FIR滤波器计算参考结果
    filtered_signal = lfilter(h_coe, 1.0, in_array)
    out_array = np.array(out_array)
    mse_error = complex_MSE(filtered_signal,out_array)
    
    # #调试代码
    # np.set_printoptions(threshold=np.inf)
    # # print(np.nonzero(out_array-filtered_signal)[0:20])
    # print(len(in_array))
    # print(len(out_array))
    # print(in_array[0:20])
    # print(filtered_signal[0:20])
    # print(out_array[0:20])

    print("test numbers:",xin_len)
    print("MSE result:",mse_error)

def read_coefficients(input_file):
    with open(input_file, 'r') as file:
        coef = []
        for line in file:
            # 去除行末的换行符和空格
            line = line.strip()
            # 处理每一行的数据
            if line:
                coef.append(int(line))
    return coef

def arg_manage():

    parser = argparse.ArgumentParser()
    parser.add_argument("--coe_dir",type=str,required=True,help="FIR系数文件路径")
    parser.add_argument("--in_bitwidths",type=int,required=False,help="单个数据输入位宽")
    parser.add_argument("--out_bitwidths",type=int,required=False,help="单个数据输出位宽")
    parser.add_argument("--VCD_dir",type=str,required=True,help="VCD文件路径")
    parser.add_argument("--sign_inter",type=bool,required=False,help="是否使用了定点整形")
    args = parser.parse_args()
    
    if args.sign_inter==True and (args.in_bitwidths is None or args.out_bitwidths is None):
        parser.error("Please provide the --in_bitwidths and --out_bitwidths for sign-interger arithmetic.")

    return args
    # 解析命令行参数


if __name__ == "__main__":

    # coef = [11,31,63,104,152,198,235,255,235,198,
    #         152,104,63,31,11]
    arg = arg_manage()
    # filename = './fir_tb.vcd' 
    # coe = './coef.txt'
    coef = read_coefficients(arg.coe_dir)
    fir_eval(h_coe=coef,in_bitwidths = arg.in_bitwidths,out_bitwidths= arg.out_bitwidths,VCD_dir=arg.VCD_dir,signinter=arg.sign_inter)



