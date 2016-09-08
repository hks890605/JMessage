//
//  JSChatInputView.m
//  JMessage
//
//  Created by Starlet on 11/10/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSChatInputView.h"
#import "UIColor+Starlet.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMEdia.h>
#import "AppInfo.h"
#import "JSAppDelegate.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface JSChatInputView()
@property (strong, nonatomic) NSTimer *durationTimer;
@property (nonatomic, strong) AVAudioPlayer *recordPlayer;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) NSString *audioRecorderFile;
@property (nonatomic, strong) AVAudioPlayer* audioPlayer;
@property (nonatomic, readwrite) NSInteger playingTime;

@end

@implementation JSChatInputView

@synthesize textView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupBackground];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupBackground];
}

- (void)setupBackground {
    textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(54, 4, 190, 32)];
    textView.isScrollable = NO;
    textView.contentInset = UIEdgeInsetsMake(0, 2, 0, 2);
    
	textView.minNumberOfLines = 1;
	textView.maxNumberOfLines = 6;
    // you can also set the maximum height in points with maxHeight
    // textView.maxHeight = 200.0f;
    textView.keyboardType = UIKeyboardTypeDefault;
	textView.returnKeyType = UIReturnKeyDefault; //just as an example
	textView.font = [UIFont systemFontOfSize:15.0f];
	textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    textView.backgroundColor = [UIColor clearColor];
    textView.placeholder = @"Please input text.";

//    UIImage *rawEntryBackground = [UIImage imageNamed:@"messagebox.png"];
//    UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
//    UIImageView *entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
//    entryImageView.frame = CGRectMake(6, 4, 246, 36);
//    entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    if (self.backImageView) {
        UIImage *rawBackground = [UIImage imageNamed:@"messagebar.png"];
        UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
        self.backImageView.image = background;
    }
    
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    textView.layer.cornerRadius = 8;
    textView.layer.borderColor = [UIColor whiteGrayColor].CGColor;
    textView.layer.borderWidth = 1.f;
    
    // view hierachy
//    [self addSubview:entryImageView];
    [self addSubview:textView];

    //self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
}

-(void)resignTextView
{
	[textView resignFirstResponder];
}

- (JSAppDelegate *)appDelegate {
	return (JSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)clearContents {
    [self.durationTimer invalidate];
    self.durationTimer = nil;

    self.textView.text = @"";
//    [self.textView resignFirstResponder];
    self.textView.hidden = NO;
    
    self.recordTimeLabel.hidden = YES;
    self.sendMessageButton.hidden = YES;
    self.recordButton.hidden = NO;
}

- (NSString*)inputValue {
    return self.textView.text;
}
- (void)setInputValue:(NSString*)value {
    self.textView.text = value;
    [self growingTextViewDidChange:self.textView];
}


#pragma mark -
- (void)sendImage {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil  destructiveButtonTitle:@"Take from Album" otherButtonTitles:@"Take a Photo", @"Cancel", nil];
    CGRect frame = self.frame;
    frame.origin.x = CGRectGetMidX(frame);
    frame.origin.y = CGRectGetMidY(frame);
    
    [sheet showFromRect:frame inView:self animated:YES];
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = YES;
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
                popoverController.delegate = self;
                
                CGRect frame = self.bounds;
                [popoverController presentPopoverFromRect:frame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            } else {
                [self.controller presentViewController:imagePicker animated:YES completion:nil];
            }
        }
    } else if (buttonIndex == 1) {//camera
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            double delayInSeconds = .3f;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePicker.delegate = self;
                imagePicker.allowsEditing = YES;
                
                imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
                [self.controller presentViewController:imagePicker animated:YES completion:nil];
            });
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:@"No Camera." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
        }
    } else if (buttonIndex == 2) {//cancel
    }
}

#pragma mark - image picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeImage]) {
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        UIImage *image = nil;
        if (url.isFileURL)
            image = [[UIImage alloc] initWithContentsOfFile:url.path];
        if (image == nil) {
            image = [info objectForKey:UIImagePickerControllerEditedImage];
            if (image == nil)
                image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
        
        if (image != nil) {
            //image = [image resizeImageWithSize:CGSizeMake(120, 160)];
            if ([self.controller respondsToSelector:@selector(sendImageToCurrentUser:)])
                [self.controller performSelector:@selector(sendImageToCurrentUser:) withObject:image afterDelay:0.f];
        }
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -

- (void)startRecording {
//    [self.textView resignFirstResponder];
    [self stopPlaying];
    
    [self.durationTimer invalidate];
    self.durationTimer = nil;

    self.recordTimeLabel.text = @"00:00";
    self.recordTimeLabel.hidden = NO;
    self.textView.hidden = YES;
    
    self.audioRecorderFile = [AppInfo tempFilePathWithFileType:MessageType_Audio filename:nil];
    //NSLog(@"Saving file here   %@",filePath);
    
    NSError *error=nil;
    // Recording settings
    NSMutableDictionary *settings =nil;
    settings = [NSMutableDictionary dictionary];
    [settings setValue: [NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [settings setValue: [NSNumber numberWithFloat:12000] forKey:AVSampleRateKey];
    [settings setValue: [NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey]; // mono
    
    [settings setValue:[NSNumber numberWithInt:12800]  forKey:AVEncoderBitRateKey];
    [settings setValue:[NSNumber numberWithInt: AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    // File URL
    NSURL *url = [NSURL fileURLWithPath:self.audioRecorderFile];
    self.audioRecorder = nil;
    // Create recorder
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
    if (error)
        NSLog(@"error: %@", [error localizedDescription]);
    else
        [self.audioRecorder prepareToRecord];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if (err) {
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    
    err = nil;
    [audioSession setActive:YES error:&err];
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    
    //NSLog(@"Recording Start");
    [self.audioRecorder record];

    self.audioDuration = 0;
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(recordingTimer:) userInfo:nil repeats:YES];
}

- (void)stopRecording:(NSArray*)chatUserList {
    [self.durationTimer invalidate];
    self.durationTimer = nil;

    self.recordButton.hidden = NO;
    self.textView.hidden = NO;
    self.recordTimeLabel.hidden = YES;
    self.sendMessageButton.hidden = YES;
    
    //    if (audioRecorder.recording)
    //    {
    [self.audioRecorder stop];
    //    }

    if (self.audioDuration > 0 && self.audioRecorderFile.isNotEmpty ) {
        NSData *audioData = [[NSData alloc] initWithContentsOfFile:self.audioRecorderFile];
        if (audioData.length <= 0)
            return;
        
        for (XMPPUserCoreDataStorageObject* chatUser in chatUserList) {
            if (![chatUser isKindOfClass:XMPPUserCoreDataStorageObject.class])
                return;

            NSString* chatUserName = chatUser.jidStr;
            NSString* chatUserFullName = chatUser.primaryResource.jidStr;
            if (chatUserFullName.length < 1)
                chatUserFullName = chatUser.jidStr;


            NSString *filePath = [AppInfo writeFileData:audioData withType:MessageType_Audio user:chatUserName filename:nil];
            [[self appDelegate] sendToOtherDevice:audioData receiverJid:chatUserFullName type:MessageType_Audio filePath:filePath];
        }
    }
}

-(void)recordingTimer:(NSTimer*)timer
{
    self.audioDuration += 1;
    if(self.audioDuration > 60) {
        if (self.audioRecorder.recording)
        {
            [self.audioRecorder stop];
        }
        
        [self.durationTimer invalidate];
        return;
    }
    //NSLog(@"===========%i",audioLength);
    
    self.recordTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", self.audioDuration / 60, self.audioDuration % 60];
}

#pragma mark - Playing

- (BOOL)isPlayingAtPath:(NSString*)audioPath {
    if (self.audioPlayer && self.audioPlayer.isPlaying) {
        NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
        return [self.audioPlayer.url isEqual:audioURL];
    }
    return NO;
}

- (void)startPlaying:(NSString*)audioPath {
    [self stopRecording:nil];
    [self stopPlaying];
    
    self.recordTimeLabel.text = @"00:00";
    self.recordTimeLabel.hidden = NO;
    self.textView.hidden = YES;

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    err = nil;
    [audioSession setActive:YES error:&err];
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
    NSURL *audioURL = [NSURL fileURLWithPath:audioPath];
    NSError *error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
    self.audioPlayer.delegate = self;
    BOOL playable = NO;

    if (error)
        NSLog(@"Audio Play Error: %@", [error localizedDescription]);
    else
        playable = [self.audioPlayer prepareToPlay];
    
    self.audioDuration = round(self.audioPlayer.duration);
    NSLog(@"Audio Duration: %.2f", self.audioPlayer.duration);
    self.playingTime = 0;
    
    if (playable) {
        self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playingTimer:) userInfo:nil repeats:YES];
    } else {
        [self audioPlayerDidFinishPlaying:self.audioPlayer successfully:YES];
        return;
    }

    [self.audioPlayer play];
}
- (void)stopPlaying {
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
    if (self.durationTimer)
        [self.durationTimer invalidate];
    self.durationTimer = nil;
    
    self.recordTimeLabel.text = @"00:00";
    self.recordTimeLabel.hidden = YES;
    self.textView.hidden = NO;
}

-(void)playingTimer:(NSTimer*)timer
{
    self.playingTime += 1;
    if(self.playingTime > self.audioDuration) {
        self.playingTime = 0;
        self.audioDuration = 0;
        [self.durationTimer invalidate];
        self.durationTimer = nil;
        
        //if timeout, but dont stop because of various file type.
//        if (self.audioPlayer.isPlaying) {
//            [self audioPlayerDidFinishPlaying:self.audioPlayer successfully:YES];
//        }
        
        return;
    }
    //NSLog(@"===========%i",audioLength);
    
    self.recordTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", self.playingTime / 60, self.playingTime % 60];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopPlaying];
    
    if (self.controller && [self.controller respondsToSelector:@selector(stopAudioPlaying)])
        [self.controller performSelector:@selector(stopAudioPlaying)];
}
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    // //NSLog(@"Decode Error occurred");
}
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
}
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    // //NSLog(@"Encode Error occurred");
}

#pragma mark -

- (NSLayoutConstraint*)flexibleHeightLC {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", NSLayoutAttributeHeight];
    NSArray* heights = [self.constraints filteredArrayUsingPredicate:predicate];
    if (heights.count > 0)
        return [heights objectAtIndex:0];
    return nil;
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect r = self.frame;
    r.size.height -= diff;
    r.origin.y += diff;

    if (self.controller && [self.controller respondsToSelector:@selector(willChangeChatInputView:frame:)])
        [(id<JSChatInputDelegate>)self.controller willChangeChatInputView:self frame:r];

    NSLayoutConstraint* heightLC = [self flexibleHeightLC];
    if (heightLC)
        heightLC.constant = r.size.height;
    else
        self.frame = r;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView {
    BOOL sendable = self.textView.text.isNotEmpty;
    self.sendMessageButton.hidden = !sendable;
    self.recordButton.hidden = sendable;
}

@end
