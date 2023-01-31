//
//  whosTyping.m
//  whosTyping
//
//  Created by Wolfgang Baird on 1/21/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import <Foundation/Foundation.h>

#import "IMTextMessagePartChatItem.h"
#import "IMFileTransfer.h"
#import "IMFileTransferCenter.h"
#import "IMDPersistentAttachmentController.h"
#import "IMHandle.h"
#import "IMPerson.h"
#import "IMAccount.h"
#import "IMAccountController.h"
#import "IMService-IMService_GetService.h"
#import "IMChat.h"
#import "IMMessage.h"
#import "IMMessageChatItem.h"
#import "IMMessageItem-IMChat_Internal.h"
#import "IMChatRegistry.h"
#import "NetworkController.h"
#import "Logging.h"
#import "ChatDisplayController.h"
#import "SelectorHelper.h"
#import "IMHandleRegistrar.h"
#import "IMChatHistoryController.h"
#import "IMChatItem.h"
#import "IDS/IDSIDQueryController.h"
#import "SocialAppsCore/SOAccountRegistrationController.h"
#import "SocialAppsCore/SOAccountAliasController.h"
#import "SocialAppsCore/SOAccountAlias.h"
//#import "MSMessageTemplateLayout.h"

@interface BlueBubblesHelper : NSObject
+ (instancetype)sharedInstance;
@end

BlueBubblesHelper *plugin;


@implementation BlueBubblesHelper

// BlueBubblesHelper is a singleton
+ (instancetype)sharedInstance {
    static BlueBubblesHelper *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

// Helper method to log a long string
-(void) logString:(NSString*)logString{

        int stepLog = 800;
        NSInteger strLen = [@([logString length]) integerValue];
        NSInteger countInt = strLen / stepLog;

        if (strLen > stepLog) {
        for (int i=1; i <= countInt; i++) {
            NSString *character = [logString substringWithRange:NSMakeRange((i*stepLog)-stepLog, stepLog)];
            NSLog(@"BLUEBUBBLESHELPER: %@", character);

        }
        NSString *character = [logString substringWithRange:NSMakeRange((countInt*stepLog), strLen-(countInt*stepLog))];
        NSLog(@"BLUEBUBBLESHELPER: %@", character);
        } else {

        NSLog(@"BLUEBUBBLESHELPER: %@", logString);
        }

}

// Called when macforge initializes the plugin
+ (void)load {
    // Create the singleton
    plugin = [BlueBubblesHelper sharedInstance];

    // Get OS version for debugging purposes
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    DLog(@"BLUEBUBBLESHELPER: %@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);

    DLog(@"BLUEBUBBLESHELPER: Initializing Connection in 5 seconds");

    // I delay here for 5 seconds because there is a strange bug where
    // the plugin will spam think that a user starts and stops typing.
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [plugin initializeNetworkController];
    });
}
+(void) getAllTransferInfoForGUID:(NSString*)guid{
    
    IMFileTransfer * newTransfer = [[IMFileTransferCenter sharedInstance] transferForGUID:guid];
    
    DLog(@"BLUEBUBBLESHELPERFT:Sticker User info %@, Is a sticker? %hhd, Is recipeBasedSticker?  %hhd ", newTransfer.stickerUserInfo, newTransfer.isSticker, newTransfer.isRecipeBasedSticker);
    DLog(@"BLUEBUBBLESHELPERFT:AUX Info %@, Attribution info? %@", newTransfer.AuxTranscoderUserInfo, newTransfer.attributionInfo);
    
}
/**
 Starts the listener for alias status changes
 */
+(void) registerListenerForActiveAliasChanged {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_aliasesChanged:) name:@"IMAccountAliasesChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_aliasesChanged:) name:@"SOAccountAliasesChangedNotification_Private" object:nil];
}
/**
 Internal reaction to notifications about aliases
 @param notification the object inside of the notification will allways be a IMAccount
 */
+(void)_aliasesChanged:  (NSNotification *)notification{
    SOAccountAliasController * account = notification.object;
    
    NSArray* currentAliases = [BlueBubblesHelper getVettedAliases];
    DLog(@"BLUEBUBBLESHELPERFT: Aliases Changed %@", currentAliases);
    [[NetworkController sharedInstance] sendMessage: @{@"event": @"aliases-updated", @"aliases": currentAliases}];
 
    
}
/**
 Get the account enabled state
 @return True if the account enabled state is 4 or false if else or not signed in
 */
+(BOOL) isAccountEnabled {
    SOAccountRegistrationController* registrationController = [SOAccountRegistrationController registrationController];
    
    if (registrationController!=NULL && [registrationController isSignedIn]){
        
        long long enabledState = [registrationController enabledState];
        NSLog(@"BLUEBUBBLESHELPER: Account Enabled State %lld", enabledState);
        return enabledState == 4;
    
    } else {
        return FALSE;
    }
    
    return [registrationController isSignedIn];
}
/**
  Gets the active alias associated with the signed account
  @return The active alias's names if not logged in returns a empty list
  */
+(NSArray *) getVettedAliases {
    
    if ([self isAccountEnabled]) {
        SOAccountRegistrationController* registrationController = [SOAccountRegistrationController registrationController];
        SOAccountAliasController * aliasController = [registrationController aliasController];
        
        NSArray* activeAliases = [aliasController vettedAliases];
        NSLog(@"BLUEBUBBLESHELPER: Vetted Aliases %@", activeAliases);
        
        
        NSMutableArray *returnedAliases = [[NSMutableArray  alloc] init];
        
        for (SOAccountAlias* alias in activeAliases) {
           
            [returnedAliases addObject:@{@"name":[alias name],@"active":[NSNumber numberWithBool:[alias active]]}];
        }
        
        return returnedAliases;
        
    } else {
        
        DLog(@"BLUEBUBBLESHELPER: Can't get aliases account not enabled");
        return @[];
        
    }
    
}
/**
 Deactivates Alias
 */
+(BOOL) deactiveAliasForName:(NSString * ) aliasName {
    
    if ([self isAccountEnabled]) {
        
    SOAccountRegistrationController* registrationController = [SOAccountRegistrationController registrationController];
    SOAccountAliasController * aliasController = [registrationController aliasController];
        @try {
            SOAccountAlias * aliasToDisable = [aliasController aliasForName:aliasName];
            DLog(@"BLUEBUBBLESHELPER: Deactivating Alias %@", aliasToDisable);
            [aliasController deactivateAliases:@[aliasToDisable]];
            return true;
        } @catch (NSException *exception) {
            DLog(@"BLUEBUBBLESHELPER: No alias found with name %@", aliasName);
            return false;
        }
    } else {
        
        DLog(@"BLUEBUBBLESHELPER: Can't disable alias, account not enabled");
        return false;
    }
}

/**
 Activate Alias
 */
+(BOOL) activativateAliasForName:(NSString * ) aliasName {
    
    if ([self isAccountEnabled]) {
        
    SOAccountRegistrationController* registrationController = [SOAccountRegistrationController registrationController];
    SOAccountAliasController * aliasController = [registrationController aliasController];
        @try {
            SOAccountAlias * aliasToActivate = [aliasController aliasForName:aliasName];
            DLog(@"BLUEBUBBLESHELPER: Activateing Alias %@", aliasToActivate);
            [aliasToActivate activate];
            return true;
        } @catch (NSException *exception) {
            DLog(@"BLUEBUBBLESHELPER: No alias found with name %@", aliasName);
            return false;
        }
    } else {
        
        DLog(@"BLUEBUBBLESHELPER: Can't activate alias, account not enabled");
        return false;
    }
}
/**
 Creates a new file transfer & moves file to attachment location

 @param originalPath The url of the file to be transferred ( Must be in a location IMessage.app has permission to access )
 @param filename The filename of the transfer to show in IMessage.app
 @return The IMFileTransfer registered with IMessage.app or nil if unable to properly create file transfer
 @warning The `originalPath` must be a URL that IMessage.app can access even with Full Disk Access some locations are off limits. One location that is safe is always safe is `~/Library/Messages`
 */
+(IMFileTransfer *) prepareFileTransferForAttachment:(NSURL *) originalPath filename: (NSString *) filename {
    // Creates the initial guid for the file transfer (invalid for sending)
    NSString*  transferInitGuid = [[IMFileTransferCenter sharedInstance] guidForNewOutgoingTransferWithLocalURL:originalPath];

    DLog(@"BLUEBUBBLESHELPER: New Transfer GUID %@ ", transferInitGuid);

    // Creates the initial transfer object but does nothing atm
    IMFileTransfer * newTransfer = [[IMFileTransferCenter sharedInstance] transferForGUID:transferInitGuid];
    
    // Get location of where attachments should be placed
    NSString* persistentPath = [[IMDPersistentAttachmentController sharedInstance] _persistentPathForTransfer:newTransfer filename:filename highQuality:TRUE];

    if (persistentPath){

        DLog(@"BLUEBUBBLESHELPER: New Attachment Path %@", persistentPath);
        NSURL * persistentURL = [NSURL fileURLWithPath:persistentPath];

        NSError *folder_creation_error;

        NSFileManager *file_manager = [NSFileManager defaultManager];
        // Create the attachment location
        [file_manager createDirectoryAtURL:[persistentURL URLByDeletingLastPathComponent] withIntermediateDirectories:TRUE attributes:nil error:&folder_creation_error];
        // Catastrophic if this error occurs ? At minimum the file wasn't moved and the path is wrong
        if(folder_creation_error){
            DLog(@"BLUEBUBBLESHELPER:  Failed to create folder: %@", folder_creation_error);
            return nil;
        }

        // Copy the file to the attachment location
        NSError *file_move_error;

        [file_manager copyItemAtURL:originalPath toURL:persistentURL error:&file_move_error];

        if(file_move_error){
            // Catastrophic if this error occurs ? At minimum the file wasn't moved and the path is wrong
            DLog(@"BLUEBUBBLESHELPER:  Failed to move file: %@", file_move_error);
            return nil;
        }

        // Say that we updated the transfers location
        [[IMFileTransferCenter sharedInstance] retargetTransfer:[newTransfer guid] toPath:persistentPath];

        // Must manually update the local url inside of the transfer
        newTransfer.localURL = persistentURL;

    }
    // Manually say the filename for the transfer
    newTransfer.transferredFilename = filename;

    // Add the File Transfer registry (Once this occurs file must be in correct location)
    // *Warning* Can fail but gives only warning in console that failed
    [[IMFileTransferCenter sharedInstance] registerTransferWithDaemon:[newTransfer guid]];

    DLog(@"BLUEBUBBLESHELPER: Transfer Registered With DAEMON %@", newTransfer);
    return newTransfer;

}

// Private method to initialize all the things required by the plugin to communicate with the main
// server over a tcp socket
-(void) initializeNetworkController {
    // Get the network controller
    NetworkController *controller = [NetworkController sharedInstance];
    [controller connect];

    // Upon receiving a message
    controller.messageReceivedBlock =  ^(NetworkController *controller, NSString *data) {
        [self handleMessage:controller message: data];
    };
    NSDictionary *message = @{@"event": @"ping", @"message": @"Helper Connected!"};
    [controller sendMessage:message];

    // DEVELOPMENT ONLY, COMMENT OUT FOR RELEASE
    // Quickly test a message event
    //     [self handleMessage:controller message:@"{\"action\":\"send-message\",\"data\":{\"chatGuid\":\"iMessage;-;elliotnash@gmail.com\",\"subject\":\"\",\"message\":\"Elliot\",\"attributedBody\":{\"runs\":[{\"attributes\":{\"__kIMMessagePartAttributeName\":0,\"__kIMMentionConfirmedMention\":\"elliotnash@gmail.com\"},\"range\":[0,6]}],\"string\":\"Elliot\"},\"effectsId\":\"com.apple.MobileSMS.expressivesend.impact\",\"selectedMessageGuid\":null}}"];
}

// Run when receiving a new message from the tcp socket
-(void) handleMessage: (NetworkController*)controller  message:(NSString *)message {
    // The data is in the form of a json string, so we need to convert it to a NSDictionary
    // for some reason the data is sometimes duplicated, so account for that
    NSRange range = [message rangeOfString:@"}\n{"];
    if(range.location != NSNotFound){
     message = [message substringWithRange:NSMakeRange(0, range.location + 1)];
    }
    DLog(@"BLUEBUBBLESHELPER: Received raw json: %@", message);
    NSError *error;
    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

    // Event is the type of packet that was sent
    NSString *event = dictionary[@"action"];
    // Data is the actual information that we need in the packet
    NSDictionary *data = dictionary[@"data"];
    // Transaction ID enables us to communicate back to the server that the action was complete
    NSString *transaction = nil;
    if ([dictionary objectForKey:(@"transactionId")] != [NSNull null]) {
        transaction = dictionary[@"transactionId"];
    }

    DLog(@"BLUEBUBBLESHELPER: Message received: %@, %@", event, data);

    if([event isEqualToString:@"send-reaction"]) {
        DLog(@"BLUEBUBBLESHELPER: REACTION INCOMING %@", data.description);

        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            //Map the reaction type
            long long reactionLong = [BlueBubblesHelper parseReactionType:(data[@"reactionType"])];

            // Get the messageItem
            [BlueBubblesHelper getMessageItem:(chat) :(data[@"selectedMessageGuid"]) completionBlock:^(IMMessage *message) {
                IMMessageItem *imMessage = (IMMessageItem *)message._imMessageItem;
                NSObject *items = imMessage._newChatItems;
                IMMessagePartChatItem *item;
                // sometimes items is an array so we need to account for that
                if ([items isKindOfClass:[NSArray class]]) {
                    item = [(NSArray *)items objectAtIndex:([data[@"partIndex"] integerValue])];
                } else {
                    item = (IMMessagePartChatItem *)items;
                }
                NSDictionary *messageSummary;
                if (item != nil) {
                    NSAttributedString *text = [item text];
                    if (text == nil) {
                        text = [message text];
                    }
                    messageSummary = @{@"amc":@1,@"ams":text.string};
                    // Send the tapback
                    // check if the body happens to be an object (ie an attachment) and send the tapback accordingly to show the proper summary
                    NSData *dataenc = [text.string dataUsingEncoding:NSNonLossyASCIIStringEncoding];
                    NSString *encodevalue = [[NSString alloc]initWithData:dataenc encoding:NSUTF8StringEncoding];
                    if ([encodevalue isEqualToString:@"\\ufffc"]) {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(@{})];
                    } else {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(messageSummary)];
                    }
                } else {
                    messageSummary = @{@"amc":@1,@"ams":message.text.string};
                    // Send the tapback
                    // check if the body happens to be an object (ie an attachment) and send the tapback accordingly to show the proper summary
                    NSData *dataenc = [[message text].string dataUsingEncoding:NSNonLossyASCIIStringEncoding];
                    NSString *encodevalue = [[NSString alloc]initWithData:dataenc encoding:NSUTF8StringEncoding];
                    if ([encodevalue isEqualToString:@"\\ufffc"]) {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(@{})];
                    } else {
                        [chat sendMessageAcknowledgment:(reactionLong) forChatItem:(item) withMessageSummaryInfo:(messageSummary)];
                    }
                }
                if (transaction != nil) {
                    [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastMessage] guid]}];
                }
                DLog(@"BLUEBUBBLESHELPER: sent reaction");
            }];
        }
    }
    // If the server tells us to start typing
     if([event isEqualToString: @"start-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // If the IMChat instance is not null, start typing
            [chat setLocalUserIsTyping:YES];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }

    // If the server tells us to stop typing
    } else if([event isEqualToString:@"stop-typing"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // If the IMChat instance is not null, stop typing
            [chat setLocalUserIsTyping:NO];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }

    // If the server tells us to mark a chat as read
    } else if([event isEqualToString:@"mark-chat-read"]) {
        // Get the IMChat instance for the guid specified in eventData
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // If the IMChat instance is not null, mark everything as read
            [chat markAllMessagesAsRead];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
    } else if([event isEqualToString:@"check-typing-status"]) {
        if(data[@"chatGuid"] != [NSNull null]) {
            [BlueBubblesHelper updateTypingStatus:data[@"chatGuid"]];
        }
    // If server tells us to change the display name
    } else if ([event isEqualToString:@"set-display-name"]) {
        if (data[@"newName"] == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide a new name for the chat!"}];
            }
            return;
        }

        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        if(chat != nil) {
            // Set the display name
            [chat _setDisplayName:(data[@"newName"])];

            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
        DLog(@"BLUEBUBBLESHELPER: Setting display name of chat %@ to %@", data[@"chatGuid"], data[@"newName"]);
    // If the server tells us to add a participant
    } else if ([event isEqualToString:@"add-participant"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (data[@"address"] == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide an address to add!"}];
            }
            return;
        }
        NSArray<IMHandle*> *handles = [[IMHandleRegistrar sharedInstance] getIMHandlesForID:(data[@"address"])];

        if (handles != nil) {
            IMAccountController *sharedAccountController = [IMAccountController sharedInstance];
            IMAccount *myAccount = [sharedAccountController mostLoggedInAccount];
            IMHandle *handle = [[IMHandle alloc] initWithAccount:(myAccount) ID:(data[@"address"]) alreadyCanonical:(YES)];
            handles = @[handle];
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to load handles for provided address!"}];
            }
            return;
        }

        if(chat != nil && [chat canAddParticipants:(handles)]) {
            [chat inviteParticipantsToiMessageChat:(handles) reason:(0)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            DLog(@"BLUEBUBBLESHELPER: Added participant to chat %@: %@", data[@"chatGuid"], data[@"address"]);
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to add address to chat!"}];
            }
            DLog(@"BLUEBUBBLESHELPER: Couldn't add participant to chat %@: %@", data[@"chatGuid"], data[@"address"]);
        }
    // If the server tells us to remove a participant
    } else if ([event isEqualToString:@"remove-participant"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (data[@"address"] == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide an address to add!"}];
            }
            return;
        }
        NSArray<IMHandle*> *handles = [[IMHandleRegistrar sharedInstance] getIMHandlesForID:(data[@"address"])];

        if (handles == nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to load handles for provided address!"}];
            }
            return;
        }

        if(chat != nil && [chat canAddParticipants:(handles)]) {
            [chat removeParticipantsFromiMessageChat:(handles) reason:(0)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            DLog(@"BLUEBUBBLESHELPER: Removed participant from chat %@: %@", data[@"chatGuid"], data[@"address"]);
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Failed to remove address from chat!"}];
            }
            DLog(@"BLUEBUBBLESHELPER: Couldn't remove participant from chat %@: %@", data[@"chatGuid"], data[@"address"]);
        }
    // If the server tells us to send a message
    } else if ([event isEqualToString:@"send-message"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        
        NSString *effectId = nil;
        if (data[@"effectId"] != [NSNull null] && [data[@"effectId"] length] != 0) {
            effectId = data[@"effectId"];
        }
        
        //[BlueBubblesHelper pocMultiFileTransferToChat:chat effectId:effectId tranaction:transaction];
        [BlueBubblesHelper sendMessage:(data) transaction:(transaction)];
        
    // If the server tells us to create a chat
    // currently unused method
    } else if ([event isEqualToString:@"create-chat"]) {
        IMAccountController *sharedAccountController = [IMAccountController sharedInstance];
        IMAccount *myAccount = [sharedAccountController mostLoggedInAccount];

        NSMutableArray<IMHandle*> *handles = [[NSMutableArray alloc] initWithArray:(@[])];
        for (NSString* str in data[@"addresses"]) {
            NSArray<IMHandle*> *handlesToAdd = [[IMHandleRegistrar sharedInstance] getIMHandlesForID:(str)];
            if (handlesToAdd == nil) {
                IMHandle *handle = [[IMHandle alloc] initWithAccount:(myAccount) ID:(str) alreadyCanonical:(YES)];
                handlesToAdd = @[handle];
            }
            [handles addObjectsFromArray:(handlesToAdd)];
        }
        IMChat *chat;
        if (handles.count > 1) {
            chat = [[IMChatRegistry sharedInstance] chatForIMHandles:(handles)];
        } else {
            chat = [[IMChatRegistry sharedInstance] chatForIMHandle:(handles[0])];
        }
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": chat.guid}];
        }
    // If server tells us to delete a chat
    } else if ([event isEqualToString:@"delete-chat"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];

        if (chat != nil) {
            [[IMChatRegistry sharedInstance] _chat_remove:(chat)];
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
        }
    } else if ([event isEqualToString:@"vetted-alias"]) {
        
        NSArray* aliasNames = [BlueBubblesHelper getVettedAliases];
        
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": aliasNames}];
        }
    } else if ([event isEqualToString:@"register-alias-listener"]) {
        
        [BlueBubblesHelper registerListenerForActiveAliasChanged];
        
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
        }
    } else if ([event isEqualToString:@"deactivate-alias"]) {
        
        NSString * alias = data[@"alias"];
        BOOL successfullDeactivation = [BlueBubblesHelper deactiveAliasForName:alias];
        if (successfullDeactivation){
        
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Unable to deactivate alias"}];
            }
        }
    } else if ([event isEqualToString:@"activate-alias"]) {
        NSString * alias = data[@"alias"];
        
        BOOL successfullActivation = [BlueBubblesHelper activativateAliasForName:alias];
        
        if (successfullActivation){
        
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction}];
            }
            
        } else {
            
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Unable to activate alias"}];
            }
        }
    } else if ([event isEqualToString:@"send-attachment"]) {
        IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
        NSString * filePath = data[@"filePath"];
        if (chat != nil ) {

            NSString *effectId = nil;
            if (data[@"effectId"] != [NSNull null] && [data[@"effectId"] length] != 0) {
                effectId = data[@"effectId"];
            }

            [BlueBubblesHelper sendFileTransferToChat:chat filePath:filePath effectId:effectId transaction:transaction];
            
        }
    }else if ([event isEqualToString:@"new-transfer"]) {
        NSString * filePath = data[@"filePath"];
        
        NSURL * fileUrl = [NSURL fileURLWithPath:filePath];
        IMFileTransfer* fileTransfer = [BlueBubblesHelper prepareFileTransferForAttachment:fileUrl filename:[fileUrl lastPathComponent]];
        if (fileTransfer!=nil) {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [fileTransfer guid]}];
            }
            DLog(@"BLUEBUBBLESHELPER: File Transfer registered: %@", [fileTransfer guid]);
        } else {
            if (transaction != nil) {
                [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Unable to create file transfer file move error occured"}];
            }
        }
        
    // If the event is something that hasn't been implemented, we simply ignore it and put this log
    } else {
        DLog(@"BLUEBUBBLESHELPER: Not implemented %@", event);
    }

}

// Retreive a IMChat instance from a given guid
//
// Uses the chat registry to get an existing instance of a chat based on the chat guid
+(IMChat *) getChat: (NSString *) guid :(NSString *) transaction {
    if(guid == nil) {
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Provide a chat GUID!"}];
        }
        return nil;
    }

    IMChat* imChat = [[IMChatRegistry sharedInstance] existingChatWithGUID: guid];

    if (imChat == nil && transaction != nil) {
        [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Chat does not exist!"}];
    }
    return imChat;
}

+(long long) parseReactionType:(NSString *)reactionType {
    NSString *lowerCaseType = [reactionType lowercaseString];

    DLog(@"BLUEBUBBLESHELPER: %@", lowerCaseType);

    if([@"love" isEqualToString:(lowerCaseType)]) return 2000;
    if([@"like" isEqualToString:(lowerCaseType)]) return 2001;
    if([@"dislike" isEqualToString:(lowerCaseType)]) return 2002;
    if([@"laugh" isEqualToString:(lowerCaseType)]) return 2003;
    if([@"emphasize" isEqualToString:(lowerCaseType)]) return 2004;
    if([@"question" isEqualToString:(lowerCaseType)]) return 2005;
    if([@"-love" isEqualToString:(lowerCaseType)]) return 3000;
    if([@"-like" isEqualToString:(lowerCaseType)]) return 3001;
    if([@"-dislike" isEqualToString:(lowerCaseType)]) return 3002;
    if([@"-laugh" isEqualToString:(lowerCaseType)]) return 3003;
    if([@"-emphasize" isEqualToString:(lowerCaseType)]) return 3004;
    if([@"-question" isEqualToString:(lowerCaseType)]) return 3005;
    return 0;
}

+(void) getMessageItem:(IMChat *)chat :(NSString *)actionMessageGuid completionBlock:(void (^)(IMMessage *message))block {
    [[IMChatHistoryController sharedInstance] loadMessageWithGUID:(actionMessageGuid) completionBlock:^(IMMessage *message) {
        DLog(@"BLUEBUBBLESHELPER: Got message for guid %@", actionMessageGuid);
        block(message);
    }];
}

+(BOOL) isTyping: (NSString *)guid {
    IMChat *chat = [BlueBubblesHelper getChat:guid :nil];
    return chat.lastIncomingMessage.isTypingMessage;
}

+(void) updateTypingStatus: (NSString *) guid {
    IMChat *chat = [BlueBubblesHelper getChat:guid :nil];
    // Send out the correct response over the tcp socket
    if(chat.lastIncomingMessage.isTypingMessage == YES) {
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": guid}];
        DLog(@"BLUEBUBBLESHELPER: %@ started typing", guid);
    } else {
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
        DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
    }
}
/**
 POC The app has to build a attrobuted body where text can be displayed anywhere and stack of images displayed anywhere
 */
+(NSAttributedString*) buildAttributedStringForMultipleFileTransfers:(NSArray*)fileTransfers  withText:(NSString*)text{
    
    NSMutableString *textBody = [[NSMutableString alloc] init];
    
    // For every file transfer add the object-replacment-char
    for (int i = 0; i < [fileTransfers count]; i++) {
        // First parts
        [textBody appendString:@"\ufffc"];
    
    }
    
    // If there is a text we want to add in the POC add it to the last message
    if(text !=nil){
        // Last part
        [textBody appendString:text];
        
    }
    
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:textBody ];
    
    // Keep track of ranges and parts
    int currentPart = 0;
    int rangeIndex = 0;
    
    // Attribute the object replacement chars
    for (IMFileTransfer* transfer in fileTransfers) {
       
            NSDictionary *dictonary = @{
                @"__kIMBaseWritingDirectionAttributeName" : @"-1", // Maybe not required?
                @"__kIMFileTransferGUIDAttributeName": [transfer guid] ,
                @"__kIMFilenameAttributeName": [transfer filename],
//                @"__kIMInlineMediaHeightAttributeName" : @"0",
//                @"__kIMInlineMediaWidthAttributeName": @"0",
                @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:currentPart]
            };
            
            // Object Replacment Chars allways are only 1 char long
            NSRange range = NSMakeRange(rangeIndex, 1);
        
            [attributedString addAttributes:dictonary range:range];
            rangeIndex++;
            currentPart++;
    }
    
    // Attribute the Text Body
    if(text){
        NSDictionary *dictonary = @{
            @"__kIMBaseWritingDirectionAttributeName" : @"-1", // Maybe not required?
            @"__kIMMessagePartAttributeName": [NSNumber numberWithInt:currentPart]
        };
        
        NSRange range = NSMakeRange(rangeIndex, [text length] );
        [attributedString addAttributes:dictonary range:range];
        rangeIndex+= [text length];
        currentPart++;
    }
    
    return attributedString;
    
}
+(void) pocMultiFileTransferToChat:(IMChat*)chat effectId:(NSString*)effectId tranaction:(NSString* ) transaction{
    
    // Select any number of file you want or have to insert into final message: Custom Test varibles ***DO!! EDIT***
    NSURL * sendingFile1 = [NSURL fileURLWithPath:@"/Users/justk/Documents/d-me-05682.jpg"];
    NSURL * sendingFile2 = [NSURL fileURLWithPath:@"/Users/justk/Library/Messages/d-me-05682 copy.jpg"];
    NSArray * files = [NSArray arrayWithObjects:sendingFile1,sendingFile2, nil];
    NSMutableArray * transfers = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray * fileTransferGUIDs = [NSMutableArray arrayWithCapacity:2];
    // End of custom test varibles
    
    // Section Simulates running On APP requesting for file transfers
    for (NSURL* file in files) {
        IMFileTransfer * transfer = [self prepareFileTransferForAttachment:file filename:[file lastPathComponent]];
        if (transfer != nil){
            [transfers addObject:transfer];
            [fileTransferGUIDs addObject:[transfer guid]];
        }
    }
    // End Section
    
    // Simulates app building attributed string ( without runs )
    NSAttributedString* attributedString = [BlueBubblesHelper buildAttributedStringForMultipleFileTransfers:transfers withText:@"Hi Tanay"];
    
    // Since I am not modifying data I am just using the same code for
    DLog(@"BLUEBUBBLESHELPERF: Attributed string with transfers: %@ %@",attributedString, transfers);
    void (^createMessage)(NSAttributedString*,NSString*, NSArray* , NSString*) = ^(NSAttributedString *message,  NSString *effectId, NSArray* fileTransferGuids,NSString *threadIdentifier) {
        IMMessage *messageToSend = [[IMMessage alloc] init];
        messageToSend = [messageToSend initWithSender:(nil) time:(nil) text:(message) messageSubject:(nil) fileTransferGUIDs:(nil) flags:(100005) error:(nil) guid:(nil) subject:(nil) balloonBundleID:(nil) payloadData:(nil) expressiveSendStyleID:(effectId)];
        [chat sendMessage:(messageToSend)];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastFinishedMessage] guid]}];
        }
    };

    createMessage(attributedString, effectId, fileTransferGUIDs, nil);
    
}

+(void) sendFileTransferToChat:(IMChat*)chat filePath:(NSString* )originFilePath  effectId:(NSString *) effectId transaction:(NSString*)transaction{


    DLog(@"BLUEBUBBLESHELPER:  Starting to create file transfer");
    NSURL * sendingFile = [NSURL fileURLWithPath:originFilePath];
    IMFileTransfer * transfer = [self prepareFileTransferForAttachment:sendingFile filename:[sendingFile lastPathComponent]];

    if (transfer){

        void (^createMessage)(NSString*, IMFileTransfer *) = ^(NSString *effectId,  IMFileTransfer *fileTransfer) {

            IMMessage *messageToSend = [[IMMessage alloc] init];
            messageToSend = [messageToSend initWithSender:(nil) fileTransfer:fileTransfer];
            messageToSend.expressiveSendStyleID = effectId;
            [messageToSend _updateFlags:18874369];
            [chat sendMessage:(messageToSend)];
            DLog(@"BLUEBUBBLESHELPER: Sent Transfer: %@", transfer);
            if (transaction != nil) {
                  [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastFinishedMessage] guid]}];
            }

        };
        createMessage(effectId, transfer);

    }else{
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"error": @"Unable to create File Transfer: File copy error occurred"}];
        }
        DLog(@"BLUEBUBBLESHELPER: Unable to create file transfer ");
    }
}

+(void) sendMessage: (NSDictionary *) data transaction:(NSString *) transaction {
    IMChat *chat = [BlueBubblesHelper getChat: data[@"chatGuid"] :transaction];
    if (chat == nil) {
        DLog(@"BLUEBUBBLESHELPER: chat is null, aborting");
        return;
    }
    
    NSArray * fileTransfersGUIDs = data[@"fileTransferGUIDs"];
    
    // TODO make sure this is safe from exceptions
    // now we will deserialize the attributedBody if it exists
    NSDictionary *attributedDict = data[@"attributedBody"];
    // we'll create the NSMutableAttributedString with the associatedBody string if we can,
    // else we'll fall back to using the message text
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: data[@"message"]];
    // if associateBody exists, we iterate through it
    if (attributedDict != NULL && attributedDict != (NSDictionary*)[NSNull null]) {
        attributedString = [[NSMutableAttributedString alloc] initWithString: attributedDict[@"string"]];
        NSArray *attrs = attributedDict[@"runs"];
        for(NSDictionary *dict in attrs)
        {
            // construct range and attributes from dict and add to NSMutableAttributedString
            NSArray *rangeArray = dict[@"range"];
            NSRange range = NSMakeRange([(NSNumber*)[rangeArray objectAtIndex:0] intValue], [(NSNumber*)[rangeArray objectAtIndex:1] intValue]);
            NSDictionary *attrsDict = dict[@"attributes"];
            [attributedString addAttributes:attrsDict range:range];
        }
    }

    NSMutableAttributedString *subjectAttributedString = nil;
    if (data[@"subject"] != [NSNull null] && [data[@"subject"] length] != 0) {
        subjectAttributedString = [[NSMutableAttributedString alloc] initWithString: data[@"subject"]];
    }
    NSString *effectId = nil;
    if (data[@"effectId"] != [NSNull null] && [data[@"effectId"] length] != 0) {
        effectId = data[@"effectId"];
    }

    void (^createMessage)(NSAttributedString*, NSAttributedString*, NSString*, NSString*, NSArray*) = ^(NSAttributedString *message, NSAttributedString *subject, NSString *effectId, NSString *threadIdentifier, NSArray* fileTransfersGUIDs) {
        IMMessage *messageToSend = [[IMMessage alloc] init];
        messageToSend = [messageToSend initWithSender:(nil) time:(nil) text:(message) messageSubject:(subject) fileTransferGUIDs:(fileTransfersGUIDs) flags:(100005) error:(nil) guid:(nil) subject:(nil) balloonBundleID:(nil) payloadData:(nil) expressiveSendStyleID:(effectId)];
        [chat sendMessage:(messageToSend)];
        if (transaction != nil) {
            [[NetworkController sharedInstance] sendMessage: @{@"transactionId": transaction, @"identifier": [[chat lastFinishedMessage] guid]}];
        }
    };

    createMessage(attributedString, subjectAttributedString, effectId, nil, fileTransfersGUIDs);
}

+(void)parsePayloadData:(NSData*) payloadData{
    NSSet * classesToUnarchive = [NSSet setWithObjects:[NSMutableString self],[NSMutableString self],[NSString self], [NSMutableDictionary self],[NSDictionary self],[NSUUID self],[NSData self],[NSURL self],[NSMutableData self],[NSValue self],[NSNumber self], nil];
    NSError * cerialError;
    
     NSDictionary * objects=   [NSKeyedUnarchiver unarchivedObjectOfClasses:classesToUnarchive fromData:payloadData error:&cerialError];
    if (cerialError == nil){
        DLog(@"BLUEBUBBLESHELPERPD: Payload Data: %@ ", objects);
        NSURL * urlString = objects[@"URL"];
        if (urlString!=nil){
        DLog(@"BLUEBUBBLESHELPERPD: Payload Data URL: %@ ", objects[@"URL"]);
            DLog(@"BLUEBUBBLESHELPERPD: Payload Data URL: %@", [urlString absoluteString]);
            DLog(@"BLUEBUBBLESHELPERPD: Payload Data URL Components: %@", [[NSURLComponents init] initWithString:[urlString absoluteString]]);

        }
    } else{
        DLog(@"BLUEBUBBLESHELPERPD: Failed To Deserialize: %@ ", cerialError);
    }
  
}
@end
ZKSwizzleInterface(FTI_IDSIDQueryController, IDSIDQueryController, NSObject)
@implementation FTI_IDSIDQueryController

-(BOOL) refreshIDStatusForDestinations:(id)arg1 service:(id)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(void(^)(id arg6))arg5{
    NSString* lisstenerId = arg3;
   
    if ([lisstenerId isEqualToString: @"AudioCallViewControllerIDSListener"]){
        NSLog(@"FT-INTERFACE: Refreshing Status of Contact for video calling %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }else{
        NSLog(@"FT-INTERFACE: Refreshing Status of Contact %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }
    return  ZKOrig(bool, arg1,arg2,arg3,arg4, arg5 );
};
- (BOOL)requestIDStatusForDestination:(id)arg1 service:(id)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(void(^)(id arg6))arg5{
    NSString* lisstenerId = arg3;
    if ([lisstenerId isEqualToString: @"AudioCallViewControllerIDSListener"]){
        NSLog(@"FT-INTERFACE: Requesting Status of Contact for video calling %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }else{
        NSLog(@"FT-INTERFACE: Requesting Status of Contact %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }
    return  ZKOrig(bool, arg1,arg2,arg3,arg4, arg5 );
}
- (BOOL)refreshIDStatusForDestination:(void(^)(void))arg1 service:(id)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(void(^)(void))arg5{
    NSString* lisstenerId = arg3;
    if ([lisstenerId isEqualToString: @"AudioCallViewControllerIDSListener"]){
        NSLog(@"FT-INTERFACE: Refreshing Status of Contact for video calling %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }else{
        NSLog(@"FT-INTERFACE: Refreshing Status of Contact %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }
    return  ZKOrig(bool, arg1,arg2,arg3,arg4, arg5 );
}
- (BOOL)requestIDStatusForDestinations:(id)arg1 service:(id)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(void(^)(void))arg5{
    NSString* lisstenerId = arg3;
   
    if ([lisstenerId isEqualToString: @"AudioCallViewControllerIDSListener"]){
        NSLog(@"FT-INTERFACE: Requesting Status of Contact for video calling %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }else{
        NSLog(@"FT-INTERFACE: Requesting Status of Contact %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }
    return  ZKOrig(bool, arg1,arg2,arg3,arg4, arg5 );
}
- (BOOL)currentIDStatusForDestination:(id)arg1 service:(id)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(void(^)(id arg7))arg5{
    NSString* lisstenerId = arg3;
    if ([lisstenerId isEqualToString: @"AudioCallViewControllerIDSListener"]){
        NSLog(@"FT-INTERFACE: Getting Current Status of Contact for video calling %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }else{
        NSLog(@"FT-INTERFACE: Getting Current Status of Contact %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }
    return  ZKOrig(bool, arg1,arg2,arg3,arg4, arg5 );
}
- (BOOL)currentIDStatusForDestinations:(id)arg1 service:(id)arg2 listenerID:(id)arg3 queue:(id)arg4 completionBlock:(void(^)(id arg7))arg5{
    NSString* lisstenerId = arg3;
    if ([lisstenerId isEqualToString: @"AudioCallViewControllerIDSListener"]){
        NSLog(@"FT-INTERFACE: Getting Current Status of Contact for video calling %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }else{
        NSLog(@"FT-INTERFACE: Getting Current Status of Contact %@, %@,%@,%@", arg1, arg2,arg3,arg4);
    }
    return  ZKOrig(bool, arg1,arg2,arg3,arg4, arg5 );
}

@end

// Credit to w0lf
// Handles all of the incoming typing events
ZKSwizzleInterface(BBH_IMMessageItem, IMMessageItem, NSObject)
@implementation BBH_IMMessageItem

- (BOOL)isCancelTypingMessage {
    // isCancelTypingMessage seems to also have some timing issues and adding a delay would fix this
    // But I would rather not rely on delays to have this program work properly
    //
    // We would rather that the typing message be cancelled prematurely rather
    // than having the typing indicator stuck permanently
    NSString *guid = [self getGuid];

    if(guid != nil) {

        if([self isLatestMessage]) {
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
            DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
        }
    }
    return ZKOrig(BOOL);
}

- (BOOL)isIncomingTypingMessage {
    // We do this because the isIncomingTypingMessage seems to have some timing
    // issues and will sometimes notify after the isCancelTypingMessage so we need to confirm
    // that the sender actually is typing
    [self updateTypingState];

    // This is here to ensure that no infinite typing occurs
    // If for whatever reason the isCancelTypingMessage does not occur,
    // this should catch the error in 2 seconds
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if(self != nil) {
            NSString *guid = [self getGuid];
            if(guid != nil) {
                if([BlueBubblesHelper isTyping:guid] == NO) {
                    [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": guid}];
                    DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", guid);
                }
            }
        }

    });

    return ZKOrig(BOOL);
}

// Check to see if this IMMessageItem matches the last IMChat's message
// This helps to avoid spamming of the tcp socket
- (BOOL) isLatestMessage {
    NSString *guid = [self getGuid];
    // Fetch the current IMChat to get the IMMessage
    IMChat *chat = [BlueBubblesHelper getChat:guid :nil];
    IMMessageItem *item = (IMMessageItem*) self;
    IMMessage *message = item.message;
    if(message.isFromMe) return NO;

    // If the IMChat's last message matches our own IMMessage, then we can proceed
    // this should avoid spamming of the tcp socket
    return chat.lastIncomingMessage.guid == message.guid;
}

// Update the typing state by checking the message state
- (void) updateTypingState {
    if(![self isLatestMessage]) return;

    NSString *guid = [self getGuid];

    // If we failed to get the guid for whatever reason, then we can't do anything
    if(guid != nil) {
        [BlueBubblesHelper updateTypingStatus:guid];
    }
}

- (NSString *) getGuid {
    IMMessageItem *item = (IMMessageItem*)self;
    if(item == nil) return nil;
    IMMessage *message = item.message;
    if(message == nil) return nil;


    // Get the guid of the message???
    IMHandle *handle = message.sender;
    if(handle == nil) return nil;
    IMChat *chat = [[IMChatRegistry sharedInstance] existingChatForIMHandle: handle];
    if(chat == nil) return nil;



    return chat.guid;
}

@end

// Credit to mrsylerpowers
// Handles all events
ZKSwizzleInterface(BBH_IMChat, IMChat, NSObject)
@implementation BBH_IMChat

- (BOOL)_handleIncomingItem:(id)arg1 {
    IMMessageItem* imMessageItem = arg1;
    IMMessage *imMessage = [imMessageItem message];
    //Complete the normal functions like writing to database and everything
    BOOL isSystemMessage = [imMessageItem isSystemMessage];
    if(isSystemMessage)
    DLog(@"BLUEBUBBLESHELPER: Recieved System Message ");

    BOOL isIncomingTypingOrCancel = [imMessageItem isIncomingTypingOrCancelTypingMessage];
    BOOL isTypingMessageOrCancel  = [imMessageItem isTypingOrCancelTypingMessage];
    if(isIncomingTypingOrCancel){
        
        BOOL incomingTypingMessage = [imMessageItem isIncomingTypingMessage];
    if(incomingTypingMessage){
        DLog(@"BLUEBUBBLESHELPER: Incoming Typing Message.....");
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": [imMessage guid]}];
    }else{
        DLog(@"BLUEBUBBLESHELPER: Incoming Cancel Typing Message");
        [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": [imMessage guid]}];
        DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", [imMessage guid]);
    }
        
    }
    if (isTypingMessageOrCancel){
        
            BOOL cancelTypingMessage = [imMessageItem isCancelTypingMessage];
        if(cancelTypingMessage){
            DLog(@"BLUEBUBBLESHELPER: Cancel typing");
            
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"stopped-typing", @"guid": [imMessage guid]}];
            DLog(@"BLUEBUBBLESHELPER: %@ stopped typing", [imMessage guid]);
        }else{
            DLog(@"BLUEBUBBLESHELPER: Typing...");
            [[NetworkController sharedInstance] sendMessage: @{@"event": @"started-typing", @"guid": [imMessage guid]}];
        }
    }
    //Complete the normal functions like writing to database and everything
    BOOL hasBeenHandled = ZKOrig(BOOL, arg1);
    if (!(isTypingMessageOrCancel || isIncomingTypingOrCancel)){
        for (NSString *fileTransferGUID in [imMessage fileTransferGUIDs]) {
            [BlueBubblesHelper getAllTransferInfoForGUID:fileTransferGUID];
        }
    DLog(@"BLUEBUBBLESHELPER: Recieved Message Update From Listener %@" ,[imMessageItem message] );
        NSData * payloadData = [imMessage payloadData];
        if (payloadData!= nil){
            DLog(@"BLUEBUBBLESHELPERPD: Recieved Payload Data");
            [BlueBubblesHelper parsePayloadData:payloadData];
        }
    [[NetworkController sharedInstance] sendMessage: @{@"event": @"message-update", @"guid": [[imMessageItem message] guid]}];
    }
    return hasBeenHandled;

}

@end


ZKSwizzleInterface(BBH_IMMessage, IMMessage, NSObject)
@implementation BBH_IMMessage

- (id)initWithSender:(id)arg1 fileTransfer:(id)arg2{
    id returnItem = ZKOrig(id, arg1,arg2);
  
        [BlueBubblesHelper getAllTransferInfoForGUID:([arg2 guid])];
    
    DLog(@"BLLUEBUBBLESHELPERM: Init with sender fileTransfer1 %@ : %@, %@",returnItem, arg1, arg2);
    return returnItem;
}
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 associatedMessageGUID:(id)arg10 associatedMessageType:(long long)arg11 associatedMessageRange:(struct _NSRange)arg12 messageSummaryInfo:(id)arg13{
    id returnItem = ZKOrig(id, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12, arg13);
    for (NSString *fileTransferGUID in  arg5) {
        [BlueBubblesHelper getAllTransferInfoForGUID:fileTransferGUID];
    }
    DLog(@"BLLUEBUBBLESHELPERM: Init with sender fileTransfer2 %@ : %@, %@, %@, %@, %@, %llu, %@, %@, %@, %@, %lld, %@, %@",returnItem, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12, arg13);
    return returnItem;
    
}
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 balloonBundleID:(id)arg10 payloadData:(id)arg11 expressiveSendStyleID:(id)arg12{
    id returnItem = ZKOrig(id, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12);
    for (NSString *fileTransferGUID in  arg5) {
        [BlueBubblesHelper getAllTransferInfoForGUID:fileTransferGUID];
    }
    DLog(@"BLLUEBUBBLESHELPERM: Init with sender fileTransfer3 %@ : %@, %@, %@, %@, %@, %llu, %@, %@, %@, %@, %@, %@",returnItem, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12);
    return returnItem;
}
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 fileTransferGUIDs:(id)arg4 flags:(unsigned long long)arg5 error:(id)arg6 guid:(id)arg7 subject:(id)arg8{
    id returnItem = ZKOrig(id, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8);
    for (NSString *fileTransferGUID in  arg4) {
        [BlueBubblesHelper getAllTransferInfoForGUID:fileTransferGUID];
    }
    DLog(@"BLLUEBUBBLESHELPERM: Init with sender fileTransfer4 Text: %@ %@, %llu, %@,", arg3, arg4, arg5, arg6);
    return returnItem;
}
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9{
    id returnItem = ZKOrig(id, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9);
    DLog(@"BLLUEBUBBLESHELPERM: Init with sender fileTransfer5 %@ : %@, %@, %@, \"\n%@\n\", %@, %llu, %@, %@, %@",returnItem, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9);
    for (NSString *fileTransferGUID in  arg5) {
        [BlueBubblesHelper getAllTransferInfoForGUID:fileTransferGUID];
    }
    return returnItem;
}
//- (id)_initWithSender:(id)arg1 time:(id)arg2 timeRead:(id)arg3 timeDelivered:(id)arg4 timePlayed:(id)arg5 plainText:(id)arg6 text:(id)arg7 messageSubject:(id)arg8 fileTransferGUIDs:(id)arg9 flags:(unsigned long long)arg10 error:(id)arg11 guid:(id)arg12 messageID:(long long)arg13 subject:(id)arg14 balloonBundleID:(id)arg15 payloadData:(id)arg16 expressiveSendStyleID:(id)arg17 timeExpressiveSendPlayed:(id)arg18 associatedMessageGUID:(id)arg19 associatedMessageType:(long long)arg20 associatedMessageRange:(struct _NSRange)arg21 messageSummaryInfo:(id)arg22{
//    id returnItem = ZKOrig(id, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22);
//    DLog(@"Init with sender fileTransfer %@ :%@, %@, %@, %@, %@, %llu, %@, %@, %@, %@, %lld, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",returnItem, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22);
//    return returnItem;
//}
//- (id)_copyWithFlags:(unsigned long long)arg1;
//- (id)copyWithZone:(struct _NSZone *)arg1;
//- (id)descriptionForPurpose:(long long)arg1 inChat:(id)arg2 senderDisplayName:(id)arg3;
//- (id)descriptionForPurpose:(long long)arg1 inChat:(id)arg2;
//- (id)descriptionForPurpose:(long long)arg1;
- (id)initWithSender:(id)arg1 time:(id)arg2 text:(id)arg3 messageSubject:(id)arg4 fileTransferGUIDs:(id)arg5 flags:(unsigned long long)arg6 error:(id)arg7 guid:(id)arg8 subject:(id)arg9 associatedMessageGUID:(id)arg10 associatedMessageType:(long long)arg11 associatedMessageRange:(struct _NSRange)arg12 associatedMessageInfo:(id)arg13{
    id returnItem = ZKOrig(id, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12, arg13);
    DLog(@"BLLUEBUBBLESHELPERM: Init with sender fileTransfer6 %@ : %@, %@, %@, %@, %@, %llu, %@, %@, %@, %@, %lld, %@, %@",returnItem, arg1,arg2, arg3, arg4, arg5, arg6,arg7, arg8, arg9, arg10, arg11, arg12, arg13);
    return returnItem;
}

@end
//ZKSwizzleInterface(WBWT_IMChat, IMChat, NSObject)
//@implementation WBWT_IMChat
//-(void)_setDisplayName:(id)arg1 {
//    DLog(@"BLUEBUBBLESHELPER: %@", [arg1 className]);
//}
//@end
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withAssociatedMessageInfo:(id)arg3 withGuid:(id)arg4 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 1");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withAssociatedMessageInfo:(id)arg3 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 2");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withMessageSummaryInfo:(id)arg3 withGuid:(id)arg4 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 3");
//    return;
//}
//
//-(void)sendMessageAcknowledgment:(long long)arg1 forChatItem:(id)arg2 withMessageSummaryInfo:(id)arg3 {
//    DLog(@"BLUEBUBBLESHELPER: sending reaction 4");
//    DLog(@"BLUEBUBBLESHELPER: %lld", arg1);
//    DLog(@"BLUEBUBBLESHELPER: %@", arg2);
//    DLog(@"BLUEBUBBLESHELPER: %@", arg3);
//
//
//    return;
//}
//
//@end

//ZKSwizzleInterface(WBWT_IMChat, IMChat, NSObject)
//@implementation WBWT_IMChat
//
//- (void) sendMessage:(id)arg1 {
//    /* REGULAR MESSAGE
//     InstantMessage[from=e:; msg-subject=(null); account:053CB8C2-3D2E-4DA6-8D29-419A2F5D4D49; flags=5; subject='(null)' text='(null)' messageID: 0 GUID:'D5E40A69-68EF-4C5D-8F3C-C1543988666F' sortID: 0 date:'627629434.853740' date-delivered:'0.000000' date-read:'0.000000' date-played:'0.000000' empty: NO finished: YES sent: NO read: NO delivered: NO audio: NO played: NO from-me: YES emote: NO dd-results: NO dd-scanned: NO error: (null) associatedMessageGUID: (null) associatedMessageType: 0 balloonBundleID: (null) expressiveSendStyleID: (null) timeExpressiveSendStylePlayed: 0.000000 bizIntent:(null) locale:(null), ]
//        REACTION
//     IMMessage[from=(null); msg-subject=(null); account:(null); flags=5; subject='(null)' text='(null)' messageID: 0 GUID:'79045C8B-1E6E-480B-8819-37E36C517578' sortID: 0 date:'627629508.210384' date-delivered:'0.000000' date-read:'0.000000' date-played:'0.000000' empty: NO finished: YES sent: NO read: NO delivered: NO audio: NO played: NO from-me: YES emote: NO dd-results: NO dd-scanned: NO error: (null) associatedMessageGUID: p:0/0C14634E-563D-408C-B9D4-805FEF7ADC7B associatedMessageType: 2001 balloonBundleID: (null) expressiveSendStyleID: (null) timeExpressiveSendStylePlayed: 0.000000 bizIntent:(null) locale:(null), ]
//
//     */
//    DLog(@"BLUEBUBBLESHELPER: sendMessage %@", arg1);
//    ZKOrig(void, arg1);
//}
//
//@end






//@interface IMDMessageStore : NSObject
//+ (id)sharedInstance;
//- (id)messageWithGUID:(id)arg1;
//@end
//
//ZKSwizzleInterface(WBWT_IMDServiceSession, IMDServiceSession, NSObject)
//@implementation WBWT_IMDServiceSession
//
//+ (id)sharedInstance {
//    return ZKOrig(id);
//}
//
//- (id)messageWithGUID:(id)arg1 {
//    return ZKOrig(id, arg1);
//}
//
//- (void)didReceiveMessageReadReceiptForMessageID:(NSString *)messageID date:(NSDate *)date completionBlock:(id)completion {
//    ZKOrig(void, messageID, date, completion);
//    Class IMDMS = NSClassFromString(@"IMDMessageStore");
//}
//
//@end

//ZKSwizzleInterface(WBWT_IMMessage, IMMessage, NSObject)
//@implementation WBWT_IMMessage
//
//- (void)_updateTimeRead:(id)arg1 {
//    ZKOrig(void, arg1);
//    DLog(@"typeStatus : _updateTimeRead");
//}
//
//@end


