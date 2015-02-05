//
//  LibHandle.h
//  LibHandle
//
//  Created by falling on 15/2/5.
//  Copyright (c) 2015年 falling. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Carbon/Carbon.h>

#import <lua.h>
#import <lualib.h>
#import <lauxlib.h>
#import <stdio.h>

static void pressKeyWithFlags(CGKeyCode virtualKey, CGEventFlags flags) {
    CGEventRef event = CGEventCreateKeyboardEvent(NULL, virtualKey, true);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGSessionEventTap, event);
    CFRelease(event);
    
    event = CGEventCreateKeyboardEvent(NULL, virtualKey, false);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGSessionEventTap, event);
    CFRelease(event);
}

static int keyWithFlags(lua_State* L)
{
    double op1 = luaL_checknumber(L,1);
    double op2 = luaL_checknumber(L,2);
    pressKeyWithFlags(op1,op2);
    return 0;
}

static const luaL_Reg mylibs[] = {
    {"keyWithFlags",keyWithFlags}
};

int luaopen_LibHandle(lua_State* L)
{
    const char* libName = "LibHandle";
    luaL_newlib(L, mylibs);
    lua_pushvalue(L, -1);
    lua_setglobal(L, libName);
    return 1;
}