#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <verilated.h>
#include <Vysyx_23060235_cpu1.h>
#include <verilated_vcd_c.h>
#include <stdint.h>
#include "Vysyx_23060235_cpu1__Dpi.h"
#include "include/include.h"
#include "svdpi.h"
//这个就是sdb
char *imgfile = NULL;

extern uint8_t pmem[PMEMSIZE];
long img_init() {
    /*
    if (imgfile == NULL) {
        printf("no img input.\n");
        return 4096;
    }*/
    char image_path[] = "/home/qh/llm-class/finalproject/qh-ysyx/npc/image.bin";
    FILE *fp = fopen(image_path, "rb");
    if(fp == NULL){
        printf("Can't open '%s'\n",imgfile);
        assert(0); 
    }
    //get the size of imgfile
    fseek(fp,0,SEEK_END); // move cur to end.
    long size = ftell(fp);
    fseek(fp,0,SEEK_SET);
    int flag=fread(pmem,size,1,fp);
    if(!flag){
        printf("read error\n");
        assert(0);
    }
    fclose(fp);
    return size;
}
/*
void npc_init(int argc,char *argv[]){
    if (argc > 1) {  
        imgfile = argv[1];
    } else {  
        printf("need imgfile name.\n");
    }
    long imgsize = img_init(imgfile);
}*/
