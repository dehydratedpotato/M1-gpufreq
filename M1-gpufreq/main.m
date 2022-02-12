//
//    MIT License
//
//    Copyright (c) 2022 BitesPotatoBacks
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//
//    Building:    clang main.m -fobjc-arc -arch arm64 -o M1-gpufreq -lIOReport -framework Foundation
//

#include <Foundation/Foundation.h>

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#define VERSION         "1.1.0"
#define ERROR(ERR)      { printf("\e[1mM1-gpufreq\e[0m:\033[0;31m error:\033[0m %s\n", ERR); exit(-1); }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

struct options
{
    float interval;
    int loop;
};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_gpu_states(void);
NSMutableArray * get_gpu_nominal_freqs(void);

void  print_gpu_freq_info(int interval);
float return_gpu_active_freq(int interval);
float return_gpu_max_freq(void);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

enum { kIOReportIterOk, kIOReportFormatState = 2 };

typedef struct IOReportSubscriptionRef* IOReportSubscriptionRef;
typedef CFDictionaryRef IOReportSampleRef;

extern IOReportSubscriptionRef IOReportCreateSubscription(void* a, CFMutableDictionaryRef desiredChannels, CFMutableDictionaryRef* subbedChannels, uint64_t channel_id, CFTypeRef b);
extern CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub, CFMutableDictionaryRef subbedChannels, CFTypeRef a);

extern CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString*, NSString*, uint64_t, uint64_t, uint64_t);
extern CFMutableDictionaryRef IOReportCopyAllChannels(uint64_t, uint64_t);

typedef int (^ioreportiterateblock)(IOReportSampleRef ch);
extern void IOReportIterate(CFDictionaryRef samples, ioreportiterateblock);

extern int IOReportGetChannelCount(CFMutableDictionaryRef);
extern int IOReportChannelGetFormat(CFDictionaryRef samples);
extern long IOReportSimpleGetIntegerValue(CFDictionaryRef, int);

extern int IOReportStateGetCount(CFDictionaryRef);
extern uint64_t IOReportStateGetResidency(CFDictionaryRef, int);
extern NSString* IOReportStateGetNameForIndex(CFDictionaryRef, int);
extern NSString* IOReportChannelGetChannelName(CFDictionaryRef);
extern NSString* IOReportChannelGetGroup(CFDictionaryRef);
extern NSString* IOReportChannelGetSubGroup(CFDictionaryRef);
extern uint64_t IOReportArrayGetValueAtIndex(CFDictionaryRef, int);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int main(int argc, char * argv[])
{
    struct options  options;
    int             option;
    int             looper = 0;
    int             counterLooper = 0;
    
    options.loop        = NAN;
    options.interval    = 1;
    
    while((option = getopt(argc, argv, "i:l:vh")) != -1)
    {
        switch(option)
        {
            case 'l':   options.loop = atoi(optarg);
                        break;
                
            case 'i':   options.interval = atoi(optarg);
                        break;
                
            case 'v':   printf("\e[1mM1-gpufreq\e[0m:: version %s\n", VERSION);
                        return 0;
                        break;
                
            case 'h':   printf("Usage:\n");
                        printf("./M1-gpufreq [options]");
                        printf("    -l <value> : loop output (0 = infinite)\n");
                        printf("    -i <value> : set sampling interval (may effect accuracy)\n");
                        printf("    -v         : print version number\n");
                        printf("    -h         : help\n");
                        return 0;
                        break;
        }
    }
    
    if (isnan(options.loop))
    {
        looper = 1;
    }
    else
    {
        if (options.loop == 0)
        {
            counterLooper = 1;
        }
        else
        {
            counterLooper = options.loop;
        }
    }
    
    printf("\e[1m\n%s%10s%14s%16s%10s\n\n\e[0m", "Name", "Type", "Max Freq", "Active Freq", "Freq %");
    
    while(looper < counterLooper)
    {
        print_gpu_freq_info(options.interval);
        
        if (options.loop != 0)
        {
            looper++;
        }
    }

    return 0;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_gpu_states(void)
{
    NSMutableArray * gpu_state_values = [NSMutableArray array];
    
    CFMutableDictionaryRef channels = IOReportCopyChannelsInGroup(@"GPU Stats", 0x0, 0x0, 0x0, 0x0);
    CFMutableDictionaryRef subbed_channels = NULL;
    
    IOReportSubscriptionRef subscription = IOReportCreateSubscription(NULL, channels, &subbed_channels, 0, 0);
    
    if (!subscription)
    {
        ERROR("error finding channel");
    }
    
    CFDictionaryRef samples = NULL;
    
    if ((samples = IOReportCreateSamples(subscription, subbed_channels, NULL)))
    {
        IOReportIterate(samples, ^(IOReportSampleRef ch)
        {
            NSString * channel_name = IOReportChannelGetChannelName(ch);
            NSString * subgroup = IOReportChannelGetSubGroup(ch);
            uint64_t value;

            for (int i = 0; i < IOReportStateGetCount(ch); i++)
            {
                if ([channel_name isEqual: @"GPUPH"] && [subgroup isEqual: @"GPU Performance States"])
                {
                    value = IOReportStateGetResidency(ch, i);
                    [gpu_state_values addObject:@(value)];
                }
            }
            
            return kIOReportIterOk;
        });
    }
    else
    {
        ERROR("error accessing performance state information");
    }
    
    if ([gpu_state_values count] == 0)
    {
        ERROR("missing performance state values");
    }
    
    return gpu_state_values;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_gpu_nominal_freqs(void)
{
    // need to figure out where to get these numbers so they don't have to be static in the code
    
    return [NSMutableArray arrayWithObjects: @"0", @"396", @"528", @"720", @"924", @"1128", @"1278", @"0", @"0", @"0", @"0", @"0", @"0", @"0", @"0", @"0", @"0", nil];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void print_gpu_freq_info(int interval)
{
    NSString * gpu_label = [NSString stringWithFormat:@"GPU %12s", "Complex"];
    
    float gpu_active_freq;
    float gpu_freq_percent;
    float gpu_max_freq = return_gpu_max_freq();
    
    gpu_active_freq = return_gpu_active_freq(interval);
    gpu_freq_percent = (gpu_active_freq / gpu_max_freq) * 100;

    if (gpu_freq_percent > 100)
    {
        gpu_freq_percent = 100;
        gpu_active_freq = gpu_max_freq;
    }
    
    if (gpu_freq_percent <= 0.009 || gpu_active_freq <= 0.009)
    {
        printf("%s%10.2f MHz%10.2f MHz %9s\n", [gpu_label UTF8String], gpu_max_freq, gpu_active_freq, "Idle");
    }
    else
    {
        printf("%s%10.2f MHz%10.2f MHz %8.2f%%\n", [gpu_label UTF8String], gpu_max_freq, gpu_active_freq, gpu_freq_percent);
    }
}

float return_gpu_active_freq(int interval)
{
    float first_sample_sum = 0;
    float last_sample_sum = 0;
    float sample_sum = 0;
    
    float state_percent = 0;
    float state_freq = 0;
    
    NSArray * gpu_nominal_freqs = get_gpu_nominal_freqs();
    
    NSMutableArray * first_sample = get_gpu_states();
    [NSThread sleepForTimeInterval:interval];
    NSMutableArray * last_sample = get_gpu_states();
    
    for (int i = 0; i < [first_sample count]; i++)
    {
        first_sample_sum += [first_sample[i] floatValue];
        last_sample_sum += [last_sample[i] floatValue];
    }
    
    sample_sum = last_sample_sum - first_sample_sum;
    
    for (int i = 0; i < [first_sample count]; i++)
    {
        state_percent = ([last_sample[i] floatValue] - [first_sample[i] floatValue]) / sample_sum;
        state_freq += state_percent * [gpu_nominal_freqs[i] floatValue];
    }
    
    if (isnan(state_freq))
    {
        return return_gpu_max_freq();
    }

    return state_freq;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_gpu_max_freq(void)
{
//    NSArray * gpu_nominal_freqs = get_gpu_nominal_freqs();
//
//    return [gpu_nominal_freqs[[gpu_nominal_freqs count] - 1] floatValue];
    
    // doing this due poor handling of nominal freqs in get_gpu_nominal_freqs() causing issues
    return 1278;
}
