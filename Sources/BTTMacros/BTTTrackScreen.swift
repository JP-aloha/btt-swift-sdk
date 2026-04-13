//
//  BTTTrackScreen.swift
//  blue-triangle
//
//  Created by Ashok Singh on 10/04/26.
//

@attached(member, names: arbitrary)
public macro BTTTrackScreen(_ name: String = "") = #externalMacro(
    module: "BTTMacrosPlugin",
    type:   "BTTTrackScreenMacro"
)
