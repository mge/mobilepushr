/*
 * PushablePhotos
 * -------------
 * Show the user a list of photos that will be pushed - and let them remove items from that list.
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <GraphicsServices/GraphicsServices.h>
#import <CoreGraphics/CGColor.h>
#import <CoreGraphics/CGColorSpace.h>
#import <UIKit/UIKit.h>
#import "MobilePushr.h"
#import "PushablePhotos.h"

@implementation PushablePhotos

- (NSArray *)cameraRollPhotos
{
	NSUserDefaults *_settings = [NSUserDefaults standardUserDefaults];
	NSString *cameraRollDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Media/DCIM"];
	NSMutableArray *photos = [NSMutableArray array];

	int currentPhotoIndex = 0;

	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: cameraRollDir];
	NSString *jpg;
	while ((jpg = [dirEnum nextObject])) {
		if ([[jpg pathExtension] isEqualToString: @"JPG"]) {
			currentPhotoIndex = [[[[jpg pathComponents] lastObject] substringWithRange: NSMakeRange(4, 4)] intValue];
			if (currentPhotoIndex > [_settings integerForKey: @"lastPushedPhotoIndex"])
				[photos addObject: [cameraRollDir stringByAppendingPathComponent: jpg]];
		}
	}

	return [NSArray arrayWithArray: photos];
}

- (id)initWithFrame: (struct CGRect)frame application: (MobilePushr *)pushr {
	if (![super initWithFrame: frame])
		return nil;

	float color[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
	struct CGColor *whiteColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), color);
	[self setBackgroundColor: whiteColor];

	_table = [[PushablePhotosTable alloc] initWithFrame: CGRectMake(frame.origin.x, frame.origin.y + 44.0f, frame.size.width, frame.size.height - (96.0f + 44.0f))];
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"Camera Roll" identifier: @"cameraroll" width: frame.size.width];
	[_table addTableColumn: col];
	[_table setSeparatorStyle: 1];
	[_table setPhotos: [self cameraRollPhotos]];
	[_table setDelegate: _table];
	[_table setDataSource: _table];
	[_table reloadData];

	_pushr = [pushr retain];

	[self addSubview: _table];

	return self;
}

- (void)dealloc
{
	[_table release];
	[_pushr release];
	[super dealloc];
}

- (void)emptyRoll {
	[_table setPhotos: [NSArray array]];
	[_table reloadData];
}

- (NSArray *)photosToPush {
	NSLog(@"Called photosToPush...");
	return [_table pushablePhotos];
}

- (void)promptUserToEditPhotos: (NSArray *)photoList {
	_photoList = [photoList retain];
    UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
    [alertSheet setTitle: @"Done pushing to Flickr"];
    [alertSheet setBodyText: @"Would you like to edit the information for your Flickr photos in Safari now?"];
    [alertSheet addButtonWithTitle: @"Proceed"];
    [alertSheet addButtonWithTitle: @"Cancel"];
    [alertSheet setDelegate: self];
    [alertSheet popupAlertAnimated: YES];
}

- (void)alertSheet: (UIAlertSheet *)sheet buttonClicked: (int)button {
	BOOL shouldTerminate = NO;

	switch (button) {
		case 1:
			[_pushr openURL: [NSString stringWithFormat: @"http://www.flickr.com/tools/uploader_edit.gne?ids=%@", [_photoList componentsJoinedByString: @","]]];
			break;
		default:
			shouldTerminate = YES;
	}

	[sheet dismiss];
	[sheet release];
	[_photoList release];

    if (shouldTerminate)
        [_pushr terminate];
}

@end

@implementation PushablePhotosTable

- (void)setPhotos: (NSArray *)photos {
	_photos = [[NSMutableArray alloc] initWithArray: photos];
	NSLog(@"Called setPhotos %@", _photos);
}

- (int)swipe: (int)type withEvent: (struct __GSEvent *)event {
	if ((4 == type) || (8 == type)) {
		struct CGRect rect = GSEventGetLocationInWindow(event);
		CGPoint point = CGPointMake(rect.origin.x, rect.origin.y - 44.0f);
		CGPoint offset = _startOffset; 
		NSLog(@"swipe: %d %f, %f", type, point.x, point.y);

		point.x += offset.x;
		point.y += offset.y;
		int row = [self rowAtPoint: point];

		[[self visibleCellForRow: row column: 0] _showDeleteOrInsertion: YES withDisclosure: NO animated: YES isDelete: YES andRemoveConfirmation: NO];
	}

	return [super swipe: type withEvent: event];
}

- (void)removePhoto: (RemovablePhotoCell *)photoCell {
	int index = [self _rowForTableCell: photoCell];
	NSLog(@"Removing photo at index %d (from %@)", index, _photos);
	[_photos removeObjectAtIndex: index];
	NSLog(@"Now photos looks like: %@", _photos);
	[self reloadData];
}

- (NSArray *)pushablePhotos {
	NSLog(@"Requesting photos for upload: %@", _photos);
	return [NSArray arrayWithArray: _photos];
}

- (int)numberOfRowsInTable: (UITable *)table {
	NSLog(@"Returning number of rows: %d", [_photos count]);
	return [_photos count];
}

- (float)table: (UITable *)table heightForRow: (int)row {
	NSLog(@"Returning height for row %d", row);
	return 96;
}

- (BOOL)table: (UITable *)table canDeleteRow: (int)row
{
	if (row < [_photos count])
		return TRUE;
}

- (BOOL)table: (UITable *)table canSelectRow: (int)row {
	/* For now, don't let the user select the row - in the future... */
	return FALSE;
}

- (void)tableRowSelected: (NSNotification *)notification {
	// TODO: trigger slide-in of the "Edit Photo Information" panel...
	return;
}

- (UITableCell *)table: (UITable *)table cellForRow: (int)row column: (UITableColumn *)col {
	RemovablePhotoCell *cell = [[RemovablePhotoCell alloc] init];
	NSString *photo = [_photos objectAtIndex: row];
	NSString *thumbnail = [[photo stringByDeletingPathExtension] stringByAppendingPathExtension: @"THM"];

	[cell setPath: photo];
	[cell setTitle: [[photo pathComponents] lastObject]];
	[cell setImage: [UIImage imageAtPath: thumbnail]];
	[cell setTable: self];

	return cell;
}

- (BOOL)respondsToSelector: (SEL)selector {
	BOOL response = [super respondsToSelector: selector];
	// NSLog(@"Called respondsToSelector: %s (returned %d)", selector, response);
	return response;
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
	// NSLog(@"methodSignatureForSelector: %s", selector);
	return [super methodSignatureForSelector: selector];
}

- (void)forwardInvocation:(NSInvocation*)invocation {
	// NSLog(@"forwardInvocation: %s", [invocation selector]);
	[super forwardInvocation: invocation];
}

- (void)dealloc {
	[_photos release];
	[super dealloc];
}

@end

@implementation RemovablePhotoCell

- (void)removeControlWillHideRemoveConfirmation:(id)fp8
{
    [self _showDeleteOrInsertion: NO withDisclosure: NO animated: YES isDelete: YES andRemoveConfirmation: NO];
}

- (void)setTable: (PushablePhotosTable *)table {
	_table = table;
}

- (void)setPath: (NSString *)path {
	[_path release];
	NSLog(@"Setting path: %@", path);
	_path = [path retain];
}

- (NSString *)path {
	return _path;
}

- (void)_willBeDeleted {
	NSLog(@"Removing photo: %@", _path);
	[_table removePhoto: self];
}

@end
