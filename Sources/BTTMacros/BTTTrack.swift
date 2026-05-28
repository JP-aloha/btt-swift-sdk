//
//  BTTTrackScreen.swift
//  blue-triangle
//
//  Created by Ashok Singh on 10/04/26.
//

#if swift(>=5.9)
@attached(member, names: arbitrary)
public macro BTTTrack(_ name: String = "") = #externalMacro(
    module: "BTTMacrosPlugin",
    type:   "BTTTrackMacro"
)
#endif
