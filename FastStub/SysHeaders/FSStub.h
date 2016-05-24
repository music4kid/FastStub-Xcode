//
//  FSStub.h
//  FastStub
//
//  Created by gao feng on 16/5/18.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#ifndef FSStub_h
#define FSStub_h

#define kSingletonImp @"\n\
+ (instancetype)sharedInstance\n\
{\n\
    static FSPlaceHolder* instance = nil;\n\
\n\
    static dispatch_once_t onceToken;\n\
    dispatch_once(&onceToken, ^{\n\
        instance = [FSPlaceHolder new];\n\
    });\n\
\n\
    return instance;\n\
}\n"

#define kSingletonHeader @"\n+ (instancetype)sharedInstance;\n"

#define kExtenionImp   @"\
@interface FSPlaceHolder ()\n\
\n\
@end\n\
\n"


#endif /* FSStub_h */
