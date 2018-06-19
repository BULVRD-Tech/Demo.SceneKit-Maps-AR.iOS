//
//  Room.swift
//  Examples
//
//  Created by David Hodge on 6/9/18.
//  Copyright © 2018 MapBox. All rights reserved.
//

import Foundation
import Parse

class Room: PFObject, PFSubclassing {
    @NSManaged var name: String?
    
    static func parseClassName() -> String {
        return "geo_reports"
    }
}
