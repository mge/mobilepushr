CC = arm-apple-darwin9-gcc
LD = $(CC)
LDID = /usr/bin/ldid

CFLAGS = -Wall -Wno-unused -std=c99 -I/var/include -I/usr/include/libxml2
LDFLAGS = -lxml2 -lobjc -framework CoreFoundation -framework CFNetwork -framework Foundation -framework UIKit -multiply_defined suppress -framework GraphicsServices -framework CoreGraphics -framework OfficeImport -L"/usr/lib" -F"/System/Library/Frameworks" -F"/System/Library/PrivateFrameworks" -bind_at_load
RESOURCES = Info.plist Default.png bottombar.png icon.png mainbutton.png mainbutton_pressed.png mainbutton_inactive.png

all: MobilePushr sign package

MobilePushr: main.o MobilePushr.o FlickrCategory.o Flickr.o PushablePhotos.o PushrNetUtil.o ExtendedAttributes.o PushrSettings.o PushrPhotoProperties.o TouchXML/CXMLDocument.o TouchXML/CXMLElement.o TouchXML/CXMLNode_PrivateExtensions.o TouchXML/CXMLDocument_PrivateExtensions.o TouchXML/CXMLNode.o TouchXML/CXMLNode_XPathExtensions.o
	@echo "Linking $@... "
	@$(CC) $(LDFLAGS) -o $@ $^
	@echo "done."

%.o: %.m
	@echo "Compiling $<... "
	@$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	@echo "done."

sign: MobilePushr
	@echo "Signing $<... "
	@$(LDID) -S $<
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
