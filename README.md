# aws-iot-lights-shadow
AWS Iot - Raspberry Pi 2 + OLED + Relay

## Overview
Simple Iot project to get familiar with AWS's Iot services. 
View a demo of the project here on YouTube: https://www.youtube.com/watch?v=RyYjR83IqWQ

The raspberry pi is constantly updating the device shadow...once there is a change detected (ie. reported value is different from the desired value), the delta is processed and the appropriate action is carried through. 

The device can be controlled with any application that can speak to the Iot device endpoint. I decided to make a small iOS app to demonstrate the capabilities of the device shadow.

This repo contains both the C code that is running on the raspberry pi as well as the swift code to compile the iOS app.

Disclaimer: Images of the lightbulb were taken from [taralazar.com]

## Prerequisites 
- AWS Account - See Amazon's "[Getting Started with AWS Iot on the Raspbery Pi]"
- AWS Iot SDK - https://github.com/aws/aws-iot-device-sdk-embedded-C
- U8glib (driver for the OLED) - https://github.com/olikraus/u8glib
- wiringPi - http://wiringpi.com/download-and-install/
- Git command line:
   
    ```sh
    $ sudo apt-get install git-core
    ```
- Cocoapods (if you want to build the iOS app). Open terminal on your Mac and run the following command:
    
    ```sh
    $ sudo gem install cocoapods
    ```

## Materials Used
- Raspberry Pi 2 with wifi dongle
- Breadboard
- SparkFun Micro OLED breakout (64" x 48") - Just to add some flare to the project
- Single LED
- 10K Resistor - Connected to the led
- 4 Channel Relay from SunFounder
- Jumper Wires - Both male-to-male and male-to-female

## Installation

#### AWS Setup
Follow the guide on Amazon's "[Getting Started with AWS Iot on the Raspbery Pi]" to log into your AWS account, create your Iot "Thing" and generate the public, private, and device keys. You also need to download the [root certificate]. Once you have the "Thing" registered in AWS and all your keys, proceed on!

#### Basic Raspberry Pi Configuration
1. Install [raspbian] on the Raspberry Pi
2. Configure wifi on the Pi
    
    ```sh
    $ sudo /etc/wpa_supplicant/wpa_supplicant.conf 
    ```
    Edit the file to include your network details
    
    ```sh
    network={
        ssid="Your ssid"
        psk="Wifi pre-shared key"
    }
    ```
    Reboot and verify you are connected to the internet (ping www.google.com)
3. Update all packages that are currently installed:
    
    ```sh
    $ sudo apt-get update
    ```
4. Now that the Pi is connected to the internet and updated, lets install all the prerequisites.

#### How to build and compile U8glib
1. Install the essential dev tools:
    
    ```sh
    $ sudo apt-get install build-essential autoconf libtool libsdl1.2-dev
    ```
2. Clone the U8glib repo:
    
    ```sh
    $ sudo git clone https://github.com/olikraus/u8glib.git
    $ cd u8glib/
    ```
3. Edit the 3 files below by uncommenting the OLED device you are using. The OLED screen I am using is connected to the Raspberry PI via SPI. Connections on the GPIO pins are as follows:
    - SCK - wPi 14 (physical # 23)
    - MOSI - wPi 12 (physical # 19)
    - CS - wPi 10 (physical # 24)
    - A0 (d/c) - wPi 16 (physical # 10)
    - Reset - wPi 15 (physical # 8)
    - LED - wpi 25 (physical # 37)
    
    I found that I had to use the HW SPI Com for the OLED. I uncommented and adjusted the following line in each file:
    
    ```sh
    U8GLIB_SSD1306_64X48 u8g(10, 16, 15);   // HW SPI Com: CS = 10, A0 = 16, Reset = 15
    ```
    
    ```sh
    $ sudo nano sys/arduino/Chess/Chess.pde
    $ sudo nano sys/arduino/U8gLogo/U8gLogo.pde
    $ sudo nano sys/arduino/GraphicsTest/GraphicsTest.pde
    ```
4. Because I'm using a fairly new device added to this library, I had to include the source file in Makefile.am. If you are using the same device I am, edit the Makefile.am file and include the following line under the "SRC_COMMON_DRV" section.
    
    ```sh
    csrc/u8g_dev_ssd1306_64x48.c \
    ```
5. We are ready to compile! Execute the following commands:
    
    ```sh
    $ sudo ./autogen.sh
    $ sudo ./configure
    $ sudo make
    $ sudo make install
    ```
6. Verify it works!
    
    ```sh
    $ sudo ./u8gwpi_logo
    ```
    You should see the U8g logo on the OLED (this took the longest to get working for me)

#### How to build and compile wiringPi
1. Navigate to your home directory:
    
    ```sh
    $ cd /home/pi/
    ```
2. Clone the wiringPi repo:
    
    ```sh
    $ sudo git clone git://git.drogon.net/wiringPi
    ```
3. Change directory and run the build script (the build script will compile and install the library for you)
   
    ```sh
    $ cd wiringPi
    $ ./build
    ```

#### How to build and compile this repo on the Raspberry Pi
1. Navigate to your home directory:
    
    ```sh
    $ cd /home/pi/
    ```
2. Clone the git repo:
    
    ```sh
    $ sudo git clone https://github.com/vjammar/aws-iot-lights-shadow.git
    cd aws-iot-lights-shadow/csrc
    ```
3. Place your private key, device key and rootCA certificate in the /certs folder
4. Navigate to the app directory:
    
    ```sh
    cd sample_apps/lights_shadow
    ```
5. Edit "aws_iot_config.h" with your information:
    
    ```
    // Get from console
    // =================================================
    #define AWS_IOT_MQTT_HOST              "" ///< Customer specific MQTT HOST. The same will be used for Thing Shadow
    #define AWS_IOT_MQTT_PORT              8883 ///< default port for MQTT/S
    #define AWS_IOT_MQTT_CLIENT_ID         "c-sdk-client-id" ///< MQTT client ID should be unique for every device
    #define AWS_IOT_MY_THING_NAME 		   "AWS-IoT-C-SDK" ///< Thing Name of the Shadow this device is associated with
    #define AWS_IOT_ROOT_CA_FILENAME       "aws-iot-rootCA.crt" ///< Root CA file name
    #define AWS_IOT_CERTIFICATE_FILENAME   "cert.pem" ///< device signed certificate file name
    #define AWS_IOT_PRIVATE_KEY_FILENAME   "privkey.pem" ///< Device private key filename
    // =================================================
    ```
6. Edit "lights_shadow.c" to use the u8g device appropriate for your environment:
    
    ```
    Line 251: 	u8g_InitHWSPI(&u8g, &u8g_dev_ssd1306_64x48_2x_hw_spi, 10, 16, 15);
    ```
7. Compile and run!
    
    ```sh
    $ make -f Makefile
    $ ./lights_shadow
    ```
8. If it works, you should see a screensaver (bouncing ball) on the OLED. Behind the scenes it is updating the device shadow every 3 seconds (you can change this interval by updating the UPDATE_FREQUENCY variable in the source code). The update gets the state of pin 25, either HIGH or LOW, and reports it back to the shadow. If the desired state is different from the reported state, it will process the delta and either turn on or off the LED. When a delta is detected, the OLED changes from the screensaver to a "NEW AWS MESSAGE!" state. Using the AWS Iot console, you can update the device shadow and in 3 seconds or less you will see the delta processed by the app on the raspberry pi. Congrats!!!

#### How to build and compile the iOS App
I also include the swift code that can be used to update the device shadow on a mobile device. In order to use the app you will first have to create a cognito identity pool id using the AWS console. The pool id should have a role that has access to the Iot services. If you need help setting this up, please pm me and I can walk you through it.

Proceed once you have a cognito identity pool id!

1. Download the "swift-src" directory to your Mac
2. Open terminal and navigate to the project directory
3. Run "pod install" to ensure you have latest pods. I am using iOS 8.4 on my iPhone so the libraries are compatible with that version. If you are using another iOS version, edit "Podfile" to include the appropriate iOS version before running the install command.
    
    ```sh
    $ sudo pod install
    ```
4. Once the pods are installed, double click on "lights_shadow.xcworkspace". This will launch XCode.
5. Edit "Constants.swift" with the right AWS region and cognito id:
    
    ```
    let AwsRegion = AWSRegionType.USEast1 // << CHANGE TO YOUR REGION
    let CognitoIdentityPoolId = "YOUR OWN COGNITO-IDENTITY-POOL-ID"
    ```
6. Edit "ViewController.swift" such that it has the right thing name:
    
    ```
    let controlThingName="YOUR THING NAME"
    ```
7. Build and run!

## Disclaimer
This project is in no way shape or form suitable for use commercial use. This project was purely for getting more familiar with Amazon's IoT service. Feel free to use this as a starting point for your own projects!

[taralazar.com]: <http://taralazar.com/2013/10/01/piboidmo-logo-badge-and-guest-bloggers/>
[Getting Started with AWS Iot on the Raspbery Pi]: <http://docs.aws.amazon.com/iot/latest/developerguide/iot-device-sdk-c.html>
[raspbian]:<https://www.raspberrypi.org/downloads/raspbian/>
[root certificate]:<https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem>
