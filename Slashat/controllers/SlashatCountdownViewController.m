//
//  SlashatCountdownViewController.m
//  Slashat
//
//  Created by Johan Larsson on 2013-03-26.
//  Copyright (c) 2013 Johan Larsson. All rights reserved.
//

#import "SlashatCountdownViewController.h"
#import "QuartzCore/QuartzCore.h"
#import "AFJSONRequestOperation.h"
#import "DateUtils.h"
#import "APIKey.h"
#import "AFHTTPClient.h"

@interface SlashatCountdownViewController ()

@end

@implementation SlashatCountdownViewController

@synthesize countdownHeaderLabel;

NSDate *nextLiveShowDate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [self initCountdownFromNextGoogleCalendarEvent];
}

- (void)initCountdownFromNextGoogleCalendarEvent
{
    NSString *parameterString = [NSString stringWithFormat:@"orderBy=startTime&singleEvents=true&timeMin=%@&key=%@", [DateUtils convertNSDateToGoogleCalendarString:[NSDate date]], GOOGLE_CALENDAR_API_KEY];
    
    NSString *encodedParameterString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)parameterString, NULL, CFSTR("+:"), kCFStringEncodingUTF8);
    
    NSString *calendarUrlString = [NSString stringWithFormat:@"https://www.googleapis.com/calendar/v3/calendars/3om4bg9o7rdij1vuo7of48n910@group.calendar.google.com/events?%@", encodedParameterString];
    
    NSURL *calendarUrl = [NSURL URLWithString:calendarUrlString];
    
    NSLog(@"calendarUrl: %@", calendarUrl);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:calendarUrl];
    [request setHTTPMethod:@"GET"];
            
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSString *headerText = [[(NSArray *)[JSON valueForKeyPath:@"items"] objectAtIndex:0] valueForKeyPath:@"summary"];
        [countdownHeaderLabel setText:headerText];
        
        NSString *dateString = [[[(NSArray *)[JSON valueForKeyPath:@"items"] objectAtIndex:0] valueForKeyPath:@"start"] valueForKeyPath:@"dateTime"];
        
        nextLiveShowDate = [DateUtils createNSDateFrom:dateString];
        [self setCountdownStartValue:nextLiveShowDate];
        [self startCountDown];
        
    } failure:^(NSURLRequest *request , NSURLResponse *response , NSError *error , id JSON){
        NSLog(@"Failed: %@",[error localizedDescription]);
    }];
    
    [operation start];
}

- (void)startCountDown
{
    // __attributes__((unused)) is to get rid of the "unused variable" warning in xcode
    NSTimer *timer __attribute__((unused)) = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCountdown:) userInfo:nil repeats:YES];
}

- (NSDate *)getNextSlashatDate
{
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setLocale:[NSLocale currentLocale]];
    
    NSDateComponents *nowComponents = [gregorian components:NSYearCalendarUnit | NSWeekCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:today];
    
    [nowComponents setWeekday:3]; //Tuesday
    
    if (nowComponents.weekday != 3) {
        [nowComponents setWeek: [nowComponents week] + 1]; //Next week
    }
    
    [nowComponents setHour:19]; //19.30
    [nowComponents setMinute:30];
    [nowComponents setSecond:0];
    
    NSDate *comingTuesday = [gregorian dateFromComponents:nowComponents];
    return comingTuesday;
}

- (void)updateCountdown:(NSTimer *)timer
{
    [self setCountdownStartValue:nextLiveShowDate];
}

- (void)setCountdownStartValue:(NSDate *)destinationDate
{
    double differenceInSeconds = [destinationDate timeIntervalSinceDate:[NSDate date]];
    
    
    int days = (int)((double)differenceInSeconds/(3600.0*24.00));
    int diffDay=differenceInSeconds-(days*3600*24);
    int hours=(int)((double)diffDay/3600.00);
    int diffMin=diffDay-(hours*3600);
    int minutes=(int)(diffMin/60.0);
    int seconds=diffMin-(minutes*60);
        
    [self setCountdownValuesWithDays:days hours:hours minutes:minutes seconds:seconds];
}

- (void)setCountdownValuesWithDays:(int)days hours:(int)hours minutes:(int)minutes seconds:(int)seconds
{
    [self setCountdownItem:days tag1:1 tag2:2];
    [self setCountdownItem:hours tag1:3 tag2:4];
    [self setCountdownItem:minutes tag1:5 tag2:6];
    [self setCountdownItem:seconds tag1:7 tag2:8];
}

- (void)setCountdownItem:(int)value tag1:(int)tag1 tag2:(int)tag2
{
    NSString *valueString = [NSString stringWithFormat:@"%02d", value];
    UILabel *valueLabel1 = (UILabel *)[self.view viewWithTag:tag1];
    UILabel *valueLabel2 = (UILabel *)[self.view viewWithTag:tag2];
    
    NSString *oldValueLabelString1 = valueLabel1.text;
    NSString *oldValueLabelString2 = valueLabel2.text;
    
    valueLabel1.text = [valueString substringToIndex:1];
    valueLabel2.text = [valueString substringFromIndex:1];
    
    if (![oldValueLabelString1 isEqualToString:[valueString substringToIndex:1]]) {
        [self animateLabel:valueLabel1];
    }
    
    if (![oldValueLabelString2 isEqualToString:[valueString substringFromIndex:1]]) {
        [self animateLabel:valueLabel2];
    }
}

- (void)animateLabel:(UILabel *)label
{
    [CATransaction begin];
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.removedOnCompletion = YES;
    animationGroup.duration = 0.85;
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    fadeAnimation.toValue = [NSNumber numberWithFloat:0.0];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    scaleAnimation.toValue = [NSNumber numberWithFloat:2.70];
    
    animationGroup.animations = [NSArray arrayWithObjects:fadeAnimation, scaleAnimation, nil];
    
    UILabel *duplicateLabel = [self duplicateLabel:label];
    [self.view addSubview:duplicateLabel];
    
    [CATransaction setCompletionBlock:^{[duplicateLabel removeFromSuperview];}];
    
    duplicateLabel.layer.bounds = duplicateLabel.frame;
    
    duplicateLabel.layer.anchorPoint = CGPointMake(.42,.5);
    duplicateLabel.layer.contentsGravity = @"center";
    duplicateLabel.layer.opacity = 0.5;
    duplicateLabel.backgroundColor = [UIColor clearColor];
        
    [duplicateLabel.layer addAnimation:animationGroup forKey:@"fadeAnimation"];
    
    [CATransaction commit];
}

- (UILabel *)duplicateLabel:(UILabel *)label
{
    UILabel *duplicate = [[UILabel alloc] initWithFrame:label.frame];
    duplicate.text = label.text;
    duplicate.textColor = label.textColor;
    duplicate.backgroundColor = label.backgroundColor;
    duplicate.font = label.font;
    return duplicate;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
