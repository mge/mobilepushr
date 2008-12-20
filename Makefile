CCROOT=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
SYSROOT=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk

CC=$(CCROOT)/arm-apple-darwin9-g++-4.0.1
CODESIGN_ALLOCATE=$(CCROOT)/codesign_allocate

LDFLAGS= -lobjc -framework Foundation -framework CoreFoundation -framework UIKit -framework CFNetwork -multiply_defined suppress  -L$(SYSROOT)/usr/lib -F$(SYSROOT)/System/Library/Frameworks
CFLAGS=-Wall -Werror -Wno-unused -std=c99 -isysroot $(SYSROOT) 

RESOURCES = Info.plist Default.png bottombar.png icon.png mainbutton.png mainbutton_pressed.png mainbutton_inactive.png

all: MobilePushr sign package

MobilePushr: main.o MobilePushr.o FlickrCategory.o Flickr.o PushablePhotos.o PushrNetUtil.o ExtendedAttributes.o PushrSettings.o PushrPhotoProperties.o TouchXML/CXMLDocument.o TouchXML/CXMLElement.o TouchXML/CXMLNode_PrivateExtensions.o TouchXML/CXMLDocument_PrivateExtensions.o TouchXML/CXMLNode.o TouchXML/CXMLNode_XPathExtensions.o
	@echo "Linking $@... "
	@$(CC) $(LDFLAGS) -o $@ $^
	@echo "done."

%.o: %.m
	@echo "Compiling $<... "
	@$(CC) -c $(CFLAGS) $< -o $@
	@echo "done."

sign: MobilePushr
	@echo "Signing $<... "
	@CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) codesign -fs "iPhone Developer: Chris Lee"  $<
	@echo "done."

package: sign
	@echo "Creating package... "
	@rm -fr Pushr.app
	@mkdir -p Pushr.app
	@cp MobilePushr Pushr.app/MobilePushr
	@cp ${RESOURCES} Pushr.app/
	@echo "done."

clean:
	@echo "Cleaning... "
	@rm -fr *.o TouchXML/*.o MobilePushr Pushr.app
	@echo "done."

install: package
	rm -rf /Applications/Pushr.app
	cp -r Pushr.app /Applications/
