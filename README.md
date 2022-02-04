<h1 align="center" style="">M1-gpufreq</h1>
<p align="center">
  Get the current frequency of your Apple M1 GPU.
</p>
<p align="center">
<a href="https://github.com/BitesPotatoBacks/M1-gpufreq/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/M1-gpufreq.svg"/>
    </a>
<!--     <a href="https://github.com/BitesPotatoBacks/M1-gpufreq/stargazers">
        <img alt="License" src="https://img.shields.io/github/stars/BitesPotatoBacks/M1-gpufreq.svg"/>
    </a> -->
    <a href="https://github.com/BitesPotatoBacks/M1-gpufreq/releases">
        <img alt="Releases" src="https://img.shields.io/github/v/release/BitesPotatoBacks/M1-gpufreq.svg"/>
    </a>
        <a href="https://cash.app/$bitespotatobacks">
        <img alt="License" src="https://img.shields.io/badge/donate-Cash_App-default.svg"/>
    </a>
    <!-- <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/osx-cpufreq.svg"/></a>-->
    <br>
</p>

## What It Does and How It Works
This project is designed to get the current frequency (or clock speed) of your Apple M1 GPU, without requiring `sudo` or a kernel extension. This near-impossible feat is achieved in a similar manner to how my [osx-cpufreq](https://github.com/BitesPotatoBacks/osx-cpufreq) project works, by accessing performance state information from `IOReport` and performing some calculations based on them during a specified time interval (default 1 second).

## Usage
### Preparation:
Download the precompiled binary from the [releases](https://github.com/BitesPotatoBacks/M1-gpufreq/releases), `cd` into your Downloads folder, and run these commands to fix the binary permissions:
```
chmod 755 ./M1-gpufreq
xattr -cr ./M1-gpufreq
```
Now you can simply run `./M1-gpufreq`.

### Example:
Here is an example running `./M1-gpufreq -l6` on an M1 Mac Mini during a Geekbench Compute run:
```
Name      Type      Max Freq     Active Freq    Freq %

GPU      Complex   1278.00 MHz     43.59 MHz     3.41%
GPU      Complex   1278.00 MHz   1153.91 MHz    90.29%
GPU      Complex   1278.00 MHz   1263.43 MHz    98.86%
GPU      Complex   1278.00 MHz    837.17 MHz    65.51%
GPU      Complex   1278.00 MHz     39.89 MHz     3.12%
GPU      Complex   1278.00 MHz   1235.26 MHz    96.66%
```

### Options
Available command line options are:
```
    -l <value> : loop output (0 = infinite)
    -i <value> : set sampling interval (may effect accuracy)
    -v         : print version number
    -h         : help
```

## Bugs and Issues
### Known Problems:
- Support for M1 Pro/Max is unofficial

If any other bugs or issues are identified, please let me know!

## Support ❤️
If you would like to support me, you can donate to my [Cash App](https://cash.app/$bitespotatobacks).
<!-- 
## Changelog

```markdown
## [1.0.0] - Feb 4, 2022
- Initial Release
``` -->
