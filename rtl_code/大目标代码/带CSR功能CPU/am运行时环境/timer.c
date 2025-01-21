#include <am.h>
#include "include/npc.h"
#include <stdio.h>

//模拟了i8253计时器的功能，i8253计时器初始化时会分别注册0x48处长度为8个字节的端口, 
//以及0xa0000048处长度为8字节的MMIO空间, 它们都会映射到两个32位的RTC寄存器. CPU可以访问这两个寄存器来获得用64位表示的当前时间
//RTC_ADDR 就是 DEVICE_BASE + 0x0000048

static uint64_t am_start_time=0;

static uint64_t am_get_time()
{
    uint32_t hi = inl(RTC_ADDR + 4);
    uint32_t lo = inl(RTC_ADDR);
    uint64_t time = ((uint64_t)hi << 32) | lo;
    //printf("hi = %x, lo = %x, time =%x\n",hi,lo,time);
    return time;
}

void __am_timer_init()
{
    am_start_time = am_get_time();
}
void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime)
{
    uptime->us = am_get_time() - am_start_time;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 1;
  rtc->month  = 9;
  rtc->year   = 2024;
}
