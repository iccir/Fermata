# Fermata

macOS is a small utility which prevents Lid Close Sleep under certain conditions.

## Why?

While DJing our weekly social dance, my laptop went to sleep and interrupted playback of the current song. Fortunately, the crowd was forgiving and the floor recovered.

After wading through logs, I discovered that the Lid Close sensor was activated. Originally, I thought that my laptop was failing; and then I realized: the sensor detects a magnetic field and **headphones are magnetic** (Apple's [support article](https://support.apple.com/en-us/HT203315) mentions speakers, but not headphones).

Many DJs and musicians use headphones during live performances. It's common to place those headphones near the laptop when not in use.

Unfortunately, macOS has no built-in option to disable the Lid Close sensor. Apps such as [InsomniaX](https://github.com/semaja2/InsomniaX) and [NoSleep](https://github.com/integralpro/nosleep) attempt to prevent this via an unsigned kernel extension; however, Apple's [System Integrity Protection](https://en.wikipedia.org/wiki/System_Integrity_Protection) prevents this on newer machines.

## Usage

1. Download and launch Fermata.
2. Click on the fermata icon in the top-right corner of your menu bar.
3. Click "Preferences…".
4. Add your favorite DJ app, which is hopefully [Embrace](https://www.ricciadams.com/projects/embrace) (shameless self-promotion, activate!).
5. Change "is launched" to "is preventing Idle Sleep".

When Embrace starts to play audio, Fermata will prevent the lid close sensor from activating. When Embrace stops playing audio, the lid close sensor will re-enable.

## How?

By examining Apple's [IOKitUser](https://opensource.apple.com/source/IOKitUser/) and [PowerManagement](https://opensource.apple.com/source/PowerManagement) projects, I learned of a private key (`kIOPMAssertionAppliesOnLidClose`) which can be used in conjunction with `IOPMAssertionDeclareUserActivity()` to prevent Lid Close sleep.

Note: this is private SPI and is **unsupported by Apple**. It could break in the future; it could cause your computer to explode; it could cause the Apple Power Management Team to show up at my doorstep and angrily chastise me; etc.

I've filed [rdar://35954315](http://openradar.appspot.com/radar?id=4931350570205184) for a public API solution to this problem.

## Disclaimer

This software disables your Lid Close Sensor. Your computer may explode. Your computer may overheat. If you have a mechanical hard drive and forget to re-enable the sensor, your hard drive may be damaged if it spins up while in your laptop bag.

Thus:

    In no event shall the authors or copyright holders be
    liable for any claim, damages or other liability, whether in an action
    of contract, tort or otherwise, arising from, out of or in connection
    with the software or the use or other dealings in the software.

