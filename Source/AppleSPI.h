#ifndef APPLE_SPI_H
#define APPLE_SPI_H

// From IOPMLibPrivate.h in IOKitUser
#define kIOPMSleepDisabledKey CFSTR("SleepDisabled")

// From IOPMLibPrivate.h in IOKitUser
CFDictionaryRef IOPMCopySystemPowerSettings(void);

// From IOPMLibPrivate.h in IOKitUser
IOReturn IOPMSetSystemPowerSetting( CFStringRef key, CFTypeRef value );

#endif /* APPLE_SPI_H */
