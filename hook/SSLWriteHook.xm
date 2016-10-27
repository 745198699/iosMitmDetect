#import <substrate.h>
#import <Security/SecureTransport.h>
#import "SocketClass.h"


//Hook the SSLWrite()
static OSStatus (*original_SSLWrite)(
                         SSLContextRef context, 
                         const void *data, 
                         size_t dataLength, 
                         size_t *processed);

static OSStatus replaced_SSLWrite(SSLContextRef context, 
                                  const void *data, 
                                  size_t dataLength, 
                                  size_t *processed){
    SocketClass *socket = [[SocketClass alloc] init];
    NSString *bundleID = [[NSBundle mainBundle]bundleIdentifier];
//    NSString *appName = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSLog(@"%@ SSLWrite len :%zu",bundleID,dataLength);
    NSData *ocData = [NSData dataWithBytes:data length:dataLength];
    NSString *ocStr = [[NSString alloc] initWithData:ocData encoding:NSUTF8StringEncoding];
//    [socket SendSocket:ocStr];
//    NSLog(@"SSLWrite data:%@",ocStr);
    NSArray *infoArray = [ocStr componentsSeparatedByString:@"\r\n"];
    
    int count = infoArray.count;
    for(int i=0;i<count;i++){
        NSString *info = [infoArray objectAtIndex:i];
        NSLog(@"%@ SSLWrite data:%@",bundleID,info);
        
        
        //判断URL是否是tweak重定向的，并根据路径判断是哪一类
        NSRange range1 = [info rangeOfString:@"/URLConnection.html"];
        if(range1.location != NSNotFound){
            NSLog(@"%@ SSLWrite :NSURLConnection has MITM",bundleID);
            
            [socket SendSocket:@"SSLWrite :NSURLConnection has MITM"];
        }
        
        NSRange range2 = [info rangeOfString:@"/UIWebView.html"];
        if(range2.location != NSNotFound){
            NSLog(@"%@ SSLWrite :UIWebView has MITM",bundleID);
            
            [socket SendSocket:@"SSLWrite :UIWebView has MITM"];
        }
        
        NSRange range3 = [info rangeOfString:@"/URLSession.html"];
        if(range3.location != NSNotFound){
            NSLog(@"%@ SSLWrite :NSURLSession has MITM",bundleID);
            
            [socket SendSocket:@"SSLWrite :NSURLSession has MITM"];
        }
    }
    
    return original_SSLWrite(context,data,dataLength,processed);
}

%ctor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"SSL Kill Switch - Hook Enabled.");
    MSHookFunction((void *) SSLWrite,(void *)  replaced_SSLWrite, (void **) &original_SSLWrite);
    [pool drain];
}