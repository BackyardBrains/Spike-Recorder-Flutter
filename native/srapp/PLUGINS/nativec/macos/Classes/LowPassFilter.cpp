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
protected:
    float cornerFrequency;
    float Q;
private:
};

LowPassFilter *lowPassFilter;
EXTERNC double createLowPassFilter(double sampleRate, double highCutOff, double q, short *data, uint32_t sampleCount){
    lowPassFilter = new LowPassFilter();
    lowPassFilter->initWithSamplingRate(sampleRate);
    if (highCutOff > sampleRate / 2.0f) highCutOff = sampleRate / 2.0f;
    lowPassFilter->setCornerFrequency(highCutOff);
    lowPassFilter->setQ(0.5f);
    lowPassFilter->filter(data, sampleCount, false);
    return 1;
}



// EXTERNC double createFilters(){
//     return 30;
// }
#endif