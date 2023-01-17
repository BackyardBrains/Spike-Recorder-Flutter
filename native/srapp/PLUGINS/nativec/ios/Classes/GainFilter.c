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

EXTERNC double GainFilter(double sample, double multiplier){
    return sample * multiplier;
}
