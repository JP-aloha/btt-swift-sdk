//
//  BreadcrumbFeatrure.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/02/26.
//


protocol BreadcrumbFeatrure {
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool
    func collect(_ breadcrumb: any BreadcrumbEvent)
}
