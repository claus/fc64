FC64
========

FC64 is a low level Commodore 64 emulator written in Actionscript 3.

It is licensed under the GNU General Public License.  See the LICENSE file for more information.

Projects
------------------

  - **libfc64** - Core library project (.swc) that includes the FC64 emulator and two display-list classes to make the emulator easy to use in other projects (*FC64Sprite* for Flash/ActionScript projects, *FC64UIComponent* for Flex projects).

  - **fc64shell** - Sample Flex project showcasing FC64 usage with some sample public domain ROMs to load and interact with.

  - **fc64-android** - AIR for Android project that allows FC64 to be packaged as an .apk to be run on Android devices  with the AIR runtime installed.

Building
------------------

The *FLEX_HOME* environment variable must be set, and must point to a Flex SDK that includes the AIR 2.5 SDK.

To compile and install the Android application, a few things need to happen:

 1. Build the libfc64.swc file.  There is no build script for this, but you can import this as a Library project into FlashBuilder to get a .swc file.
 2. Make sure the AIR Runtime is installed on your phone.
 3. Connect your phone to your computer
 4. Make sure you have a certificate available for code signing, and update the build.properties file with both the path to the certificate and the password.
 5. Navigate to the fc64-android directory and execute the following:
	ant -f ./build/build.xml

The default target will compile the code, package the .apk file, and install it on your device.