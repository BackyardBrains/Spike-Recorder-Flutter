//
// Created by Stanislav Mircic  <stanislav at backyardbrains.com>
//
#ifndef SPIKE_RECORDER_ANDROID_LOWPASSFILTER
#define SPIKE_RECORDER_ANDROID_LOWPASSFILTER

#include "FilterBase.cpp"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include<stdint.h>

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif


class LowPassFilter : public FilterBase {
public:
    // LowPassFilter(){};
    LowPassFilter() = default;
    void calculateCoefficients() {
        if ((cornerFrequency != 0.0f) && (Q != 0.0f)) {
            intermediateVariables(cornerFrequency, Q);


            a0 = 1 + alpha;
            b0 = ((1 - omegaC) / 2) / a0;
            b1 = ((1 - omegaC)) / a0;
            b2 = ((1 - omegaC) / 2) / a0;
            a1 = (-2 * omegaC) / a0;
            a2 = (1 - alpha) / a0;

            setCoefficients();
        }
    }

    void setCornerFrequency(float newCornerFrequency) {
        cornerFrequency = newCornerFrequency;
        calculateCoefficients();
    }

    void setQ(float newQ) {
        Q = newQ;
        calculateCoefficients();
    }
    float cornerFrequency = 0;
    float Q = 0;

protected:
private:
};

int logIdx = -1;
LowPassFilter* lowPassFilters;
EXTERNC double createLowPassFilter(short channelCount, double sampleRate, double cutOff, double q){
    lowPassFilters = new LowPassFilter[channelCount];
    // int sum = 0;
    for( int i = 0; i < channelCount; i++ )
    {
        // LowPassFilter lowPassFilter = LowPassFilter();
        lowPassFilters[i] = LowPassFilter();
        // LowPassFilter lowPassFilter = lowPassFilters[i];
        lowPassFilters[i].initWithSamplingRate(sampleRate);
        if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
        lowPassFilters[i].setCornerFrequency(cutOff);
        lowPassFilters[i].setQ(q);
        
        // lowPassFilters[i] = lowPassFilter;
    }
    // return lowPassFilters[0].cornerFrequency;
    return 1;
    // return 2 * M_PI * cutOff / sampleRate;
    // return q;
}

EXTERNC double initLowPassFilter(short channelCount, double sampleRate, double cutOff, double q){
    for( uint32_t i = 0; i < channelCount; i++ )
    {
        LowPassFilter lowPassFilter = lowPassFilters[i];
        lowPassFilter.initWithSamplingRate(sampleRate);
        if (cutOff > sampleRate / 2.0f) cutOff = sampleRate / 2.0f;
        lowPassFilter.setCornerFrequency(cutOff);
        lowPassFilter.setQ(q);
    }
    return 1;
}

EXTERNC double applyLowPassFilter(short channelIdx, short *data, uint32_t sampleCount){
    lowPassFilters[channelIdx].filter(data, sampleCount, false);
    // return -1.0;
    // for( int i = 0; i < sampleCount; ++i )
    // {
    //     data[i] = -3000;
    // }
    // logIdx++;
    // // return logIdx;
    // if (logIdx == 0){
    //     // return lowPassFilters[channelIdx].coefficients[0];
    //     return -1;
    // }else
    // if (logIdx == 1){
    //     // return lowPassFilters[channelIdx].coefficients[1];
    //     return -1;
    // }else
    // if (logIdx == 2){
    //     // return lowPassFilters[channelIdx].coefficients[2];
    //     return -1;
    // }else
    // if (logIdx == 3){    
    //     // return lowPassFilters[channelIdx].coefficients[3];
    //     return -1;
    // }else
    // if (logIdx == 4){   
    //     // return lowPassFilters[channelIdx].omega;
    //     return -1;
    // }else
    // if (logIdx == 5){
    //     // return lowPassFilters[channelIdx].omegaS;
    //     return -100000000;
    // }else
    // if (logIdx == 6){
    //     return lowPassFilters[channelIdx].gOutputKeepBuffer[0];
    //     // return lowPassFilters[channelIdx].omegaC;
    // }else
    // if (logIdx == 7){
    //     return lowPassFilters[channelIdx].gOutputKeepBuffer[1];
    //     // return lowPassFilters[channelIdx].alpha;
    // }else
    // if (logIdx == 8){
    //     return lowPassFilters[channelIdx].gInputKeepBuffer[0];
    // }else
    // if (logIdx == 9){
    //     logIdx = -1;
    //     return lowPassFilters[channelIdx].gInputKeepBuffer[1];
    // }
    return -1;


}


// EXTERNC double createFilters(){
//     return 30;
// }
#endif