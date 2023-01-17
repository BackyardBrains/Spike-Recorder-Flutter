#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include "GainFilter.h"

#include<stdint.h>
#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

EXTERNC typedef struct {
    const char* info;
} MyStruct;

EXTERNC MyStruct CreateStruct() {
    // MyStruct test = new MyStruct();
    // MyStruct.info = "Hello Dart!";
    // return MyStruct;
    // return {.info = "Hello Dart!"};

    MyStruct test ={
        info: "Hello FFI"
    };
    return test;
}

EXTERNC const char* GetInfo(MyStruct* s) {
    return s->info;
}


double result;
double GainFilter(double sample, double multiplier){
    result = sample * multiplier;
    return result;
}

double ReturnGainFilter(double sample){
    return result * 80;
}


