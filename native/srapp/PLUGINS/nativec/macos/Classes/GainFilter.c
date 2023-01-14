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
double result;
double GainFilter(double sample, double multiplier){
    result = sample * multiplier;
    return result;
}

double ReturnGainFilter(double sample){
    return result * 80;
}


