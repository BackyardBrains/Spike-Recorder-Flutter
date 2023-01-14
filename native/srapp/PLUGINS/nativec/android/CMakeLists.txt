cmake_minimum_required(VERSION 3.4.1)

add_library( native_nativec

             SHARED

             ../ios/Classes/GainFilter.c ../ios/Classes/resamplesubs.c )