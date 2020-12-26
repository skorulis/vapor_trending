//
//  File.swift
//  
//
//  Created by Alexander Skorulis on 22/12/20.
//

import Foundation

struct GoogleTrendingSearch: Decodable {
    
    struct Title: Decodable {
        let query: String
        let exploreLink: String
    }
    
    struct Article: Decodable {
        let title: String
        let timeAgo: String
        let source: String
        let url: String
        let snippet: String
    }
    
    let title: Title
    let formattedTraffic: String
    let relatedQueries: [Title]
    let articles: [Article]
    
    var trafficValue: Int {
        if formattedTraffic.hasSuffix("K+") {
            return (Int(formattedTraffic.replacingOccurrences(of: "K+", with: "")) ?? 0) * 1000
        } else if formattedTraffic.hasSuffix("M+") {
            return (Int(formattedTraffic.replacingOccurrences(of: "M+", with: "")) ?? 0) * 1000000
        }
        return Int(formattedTraffic) ?? 0
    }
    
}

struct GoogleTrendingDay: Decodable {
    
    let date: String
    let formattedDate: String
    let trendingSearches: [GoogleTrendingSearch]
    
}

struct GoogleDailyTrendsResponse: Decodable {
    
    let trendingSearchesDays: [GoogleTrendingDay]
    
}
