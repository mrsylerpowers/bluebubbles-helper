//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Oct 15 2018 10:31:50).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import "NSObject-Protocol.h"

@class IMHandle, IMServiceImpl, NSAttributedString, NSDate;

@protocol IMChatTranscriptItem
@property(readonly, nonatomic) IMHandle *handle;
@property(readonly, nonatomic) IMServiceImpl *service;
@property(readonly, nonatomic) NSDate *transcriptDate;
@property(readonly, copy, nonatomic) NSAttributedString *transcriptText;
@property(readonly, nonatomic) BOOL wantsTail;
@property(readonly, nonatomic, getter=isFromMe) BOOL fromMe;
@end

