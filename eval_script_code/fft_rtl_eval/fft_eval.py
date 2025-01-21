import numpy as np
import re
from scipy.fftpack import fft
import argparse

def arg_manage():

    parser = argparse.ArgumentParser()
    parser.add_argument("--fft_channels",type=int,required=True,help="FFT 总通道数")
    parser.add_argument("--in_bitwidths",type=int,required=True,help="单个数据输入位宽")
    parser.add_argument("--out_bitwidths",type=int,required=True,help="单个数据输出位宽")
    parser.add_argument("--VCD_dir",type=str,required=True,help="VCD文件路径")
    args = parser.parse_args()
    
    return args
    # 解析命令行参数


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
        print(signal['changes'][0])
        print("")

def signed_bin_to_dec(bin_str,bitwidths):
    
    # 将二进制字符串转换为整数
    value = int(bin_str, 2)
    
    if value & (1 << (bitwidths - 1)):
        value -= (1 << bitwidths)
    
    return value

def complex_MSE(x,x_ref):
    return np.mean(np.abs(x-x_ref)**2)

def fft_eval(fft_channels=8,in_bitwidths=24,out_bitwidths=24,VCD_dir=None):
    
    in_real_names  = []
    in_image_names = []
    out_real_names  = []
    out_image_names = []

    for i in range(fft_channels):
        in_real_names.append("x"+str(i)+"_real")    
        in_image_names.append("x"+str(i)+"_imag")

    for i in range(fft_channels):
        out_real_names.append("y"+str(i)+"_real")
        out_image_names.append("y"+str(i)+"_imag")

    signals, timestamps = read_vcd(VCD_dir)
    
    check_port_name = []
    for signal_id, signal in signals.items():
        check_port_name.append(signal['name'])

    assert all(item in check_port_name for item in in_real_names) & all(item in check_port_name for item in in_image_names),"Make sure your input port name is x{$channel_index}_real or x{$channel_index}_imag!"
    assert all(item in check_port_name for item in out_real_names) & all(item in check_port_name for item in out_image_names),"Make sure your output port name is y{$channel_index}_real or y{$channel_index}_imag!"
    assert 'yout_valid' in check_port_name,"Make sure you have yout_valid signal!"  
    valid_time = 0
    in_num = np.empty((fft_channels))
    out_num = np.empty((fft_channels))
    
    #数据准备for
    for signal_id, signal in signals.items():
        #提取valid值为高的时刻
        if signal['name'] == 'yout_valid':
            for change in signal['changes']:
                time, value = change
                if(value == '1'):
                    if valid_time<int(time):
                        valid_time = int(time)
                    
    for signal_id, signal in signals.items():        
        #提取输入数量
        if signal['name'] in in_real_names:
            in_real_length = len(signal['changes'])
            index_in_real = in_real_names.index(signal['name'])
            in_num[index_in_real] = in_real_length
        
        if signal['name'] in out_real_names:
            index_out_real = out_real_names.index(signal['name'])
            spilt_signals=[]
            #根据Valid统计除X值以外有效y的个数
            for change in signal['changes']:
                time , value = change
                if(int(time) >= valid_time):
                    spilt_signals.append(value)
            out_num[index_out_real] = len(spilt_signals)
    
    assert np.all(in_num==in_num[0]), "Input channels have different lengths!"
    assert np.all(out_num==out_num[0]), "Output channels have different lengths!"

    #FFT电路输入输出有效组数
    eval_in_groups = int(in_num[0])
    eval_out_groups = int(out_num[0])

    if eval_in_groups > eval_out_groups:
        eval_in_groups = eval_out_groups

    assert eval_in_groups==eval_out_groups,"Input channels and Output channels have different lengths!"

    in_array = np.empty((fft_channels,eval_in_groups,2))
    out_array = np.empty((fft_channels,eval_out_groups,2))

    for signal_id, signal in signals.items():
        # 寻找各输入通道实数输入结果
        if signal['name'] in in_real_names:
            index_in_real = in_real_names.index(signal['name'])
            
            for i in range(eval_in_groups):
                time , value = signal['changes'][i]
                in_array[index_in_real][i][0] = signed_bin_to_dec(value,in_bitwidths)
                
        # 寻找各输入通道虚数输入结果
        if signal['name'] in in_image_names:
            index_in_image = in_image_names.index(signal['name'])
   
            for i in range(eval_in_groups):
                time , value = signal['changes'][i]
                in_array[index_in_image][i][1] = signed_bin_to_dec(value,in_bitwidths)

        
        # 寻找各输出通道实数输出结果
        if signal['name'] in out_real_names:
            index_out_real = out_real_names.index(signal['name'])
            
            #去除X值
            spilt_signals=[]
            for change in signal['changes']:
                time , value = change
                if(int(time) >= valid_time):
                    spilt_signals.append(change)
            #循环提取
            for i in range(eval_out_groups):
                time , value = spilt_signals[i]
                out_array[index_out_real][i][0] = signed_bin_to_dec(value,out_bitwidths)
        
        #寻找各输出通道虚数输出结果
        if signal['name'] in out_image_names:
            index_out_image = out_image_names.index(signal['name'])
            
            #去除X值
            spilt_signals=[]
            for change in signal['changes']:
                time , value = change
                if(int(time) >= valid_time):
                    spilt_signals.append(change)
            #循环提取
            for i in range(eval_out_groups):
                time , value = spilt_signals[i]
                out_array[index_out_image][i][1] = signed_bin_to_dec(value,out_bitwidths)
    
    #合成复数
    in_complex = np.transpose(in_array[:,:,0] + 1j * in_array[:,:,1])
   
    fft_ref = fft(in_complex)  
    # print("FFT result:", fft_ref)
    
    #合成复数
    out_complex = np.transpose(out_array[:,:,0] + 1j * out_array[:,:,1])
    # print("RTL calculate result:",out_complex)
    
    mse_error = complex_MSE(out_complex,fft_ref)
    print("Each channel total test input numembers:",eval_in_groups)
    print("MSE result:",mse_error)

if __name__ == "__main__":
    args = arg_manage()
    # filename = './fft4/fft4_tb.vcd'  # fft4 VCD文件路径
    # filename = './fft8/fft8.vcd'  # fft8 VCD文件路径
    fft_eval(fft_channels=args.fft_channels,in_bitwidths=args.in_bitwidths,out_bitwidths=args.out_bitwidths,VCD_dir=args.VCD_dir) 
    