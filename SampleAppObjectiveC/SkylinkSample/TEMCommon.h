//
//  TEMCommon.h
//  TEM
//
//  Created by macbookpro on 02/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#ifndef TEM_TEMCommon_h
#define TEM_TEMCommon_h

// Notifications
#define TEM_MINIMIZE_PRESENCE @"MINIMIZE_PRESENCE"

// Paddings
#define TEM_SIBLING_PADDING 8
#define TEM_PARENT_PADDING 20

// Macro for version checking
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#endif
