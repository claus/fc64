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