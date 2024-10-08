# Fermata

Fermata is a small macOS utility which prevents Lid Close Sleep under certain conditions:

1. The user manually checks the "Prevent Lid Close Sleep" menu item.
2. A specified application is launched.
3. A specified application prevents Idle Sleep (which is common for music-playing applications).

## Why?

While DJing our weekly social dance, my laptop went to sleep and interrupted playback of the current song. Fortunately, the crowd was forgiving and the floor recovered.

After wading through logs, I discovered that the Lid Close sensor was activated. Originally, I thought that my laptop was failing; and then I realized: the sensor detects a magnetic field and **headphones are magnetic** (Apple's [support article](https://support.apple.com/en-us/HT203315) mentions speakers, but not headphones).

Many DJs and musicians use headphones during live performances. It's common to place those headphones near the laptop when not in use.

Unfortunately, macOS has no built-in option to disable the Lid Close sensor. Apps such as [InsomniaX](https://github.com/semaja2/InsomniaX) and [NoSleep](https://github.com/integralpro/nosleep) attempt to prevent it via a kernel extension. I had issues getting these apps to work due to Apple's [System Integrity Protection](https://en.wikipedia.org/wiki/System_Integrity_Protection) and [User-Approved Kernel Extension Loading](https://developer.apple.com/library/content/technotes/tn2459/_index.html). 

## Installation and Usage

1. [Download the latest release](https://github.com/iccir/Fermata/releases) of Fermata.
2. Copy the downloaded application to your `/Applications` folder and launch it.
3. Click on the fermata icon in the top-right corner of your menu bar.
4. Click "Preferences…".
5. Add your favorite music app. By default, Fermata is configured to work with [Embrace](https://www.ricciadams.com/projects/embrace) (my DJ app).

When Embrace starts to play audio, it prevents Idle Sleep via a call to `-[NSProcessInfo beginActivityWithOptions:reason:]`. Fermata sees this prevention and "upgrades" it to also prevent Lid Close Sleep. When Embrace stops playing audio, it once again allows Idle Sleep. Fermata sees this and re-enables Lid Close Sleep.

Some applications may not properly prevent Idle Sleep. For these apps, use the "is running" option rather than "is preventing Idle Sleep".

## How?

Note: this is private SPI and is **unsupported by Apple**. It could break in the future; it could cause your computer to explode; it could cause the Apple Power Management Team to show up at my doorstep and angrily chastise me; etc.

#### Fermata 1.1

In a macOS 10.13 update, Apple protected the private `kIOPMAssertionAppliesOnLidClose` with the `com.apple.private.iokit.assertonlidclose` restricted entitlement. Fortunately, [lozzd](https://github.com/lozzd) suggested the `pmset -b disablesleep 1` command, which Fermata now uses.

#### Fermata 1.0

By examining Apple's [IOKitUser](https://opensource.apple.com/source/IOKitUser/) and [PowerManagement](https://opensource.apple.com/source/PowerManagement) projects, I learned of a private key (`kIOPMAssertionAppliesOnLidClose`) which can be used in conjunction with `IOPMAssertionDeclareUserActivity()` to prevent Lid Close sleep.

I've filed [rdar://35954315](http://openradar.appspot.com/radar?id=4931350570205184) for a public API solution to this problem.

## License

I only care about proper attribution in source code. While
attribution in binary form is welcomed, it is not necessary.

Hence, unless otherwise noted, all files in this project are licensed under
both the [MIT License](https://github.com/iccir/Fermata/blob/main/LICENSE)
OR the [1-clause BSD License](https://opensource.org/license/bsd-1-clause).
You may choose either license.

`SPDX-License-Identifier: MIT OR BSD-1-Clause`

## Disclaimer

This software disables your Lid Close Sensor. While Apple laptops are designed to operate in ["closed-display mode"](https://support.apple.com/en-us/HT201834), Fermata makes it easier to accidentally toss a running laptop into your bag. This can result in overheating or damage to mechanical hard drives.

Thus:

    In no event shall the authors or copyright holders be
    liable for any claim, damages or other liability, whether in an action
    of contract, tort or otherwise, arising from, out of or in connection
    with the software or the use or other dealings in the software.

