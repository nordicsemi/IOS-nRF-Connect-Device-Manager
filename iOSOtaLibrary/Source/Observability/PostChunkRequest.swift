//
//  PostChunkRequest.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 19/8/22.
//  Copyright © 2025 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

// MARK: - PostChunkRequest

extension HTTPRequest {

    static func post(_ chunk: ObservabilityChunk, with chunkAuth: ObservabilityAuth) -> HTTPRequest {
        var httpRequest = HTTPRequest(url: chunkAuth.url)
        httpRequest.setMethod(HTTPMethod.POST)
        httpRequest.setHeaders([
            "Content-Type": "application/octet-stream",
            chunkAuth.authKey: chunkAuth.authValue,
            "User-Agent": otaLibraryUserAgent()
        ])
        httpRequest.setBody(chunk.data)
        return httpRequest
    }
    
    /**
     - Reference: [Memfault Cloud iOS GitHub Implementation](https://github.com/memfault/memfault-cloud-ios/blob/c40932ac77469e7fe7e18d1d4c126ae47ec92b13/MemfaultCloud/Classes/MemfaultApi.m#L378)
     */
    static func post(chunks: [ObservabilityChunk], with chunkAuth: ObservabilityAuth) -> HTTPRequest {
        if let singleChunk = chunks.first, chunks.count == 1 {
            return post(singleChunk, with: chunkAuth)
        }
        
        let boundary: String = "--mflt-\(UUID().uuidString)"
        var httpRequest = HTTPRequest(url: chunkAuth.url)
        httpRequest.setMethod(HTTPMethod.POST)
        httpRequest.setHeaders([
            "Content-Type": "multipart/mixed; boundary=\(boundary)",
            chunkAuth.authKey: chunkAuth.authValue,
            "User-Agent": otaLibraryUserAgent()
        ])
        
        var body = Data()
        for chunk in chunks {
            if let chunkStart = "--\(boundary)\r\n".data(using: .utf8) {
                body.append(chunkStart)
            }
            
            if let chunkContentLength = "Content-Length: \(chunk.data.count)".data(using: .utf8) {
                body.append(chunkContentLength)
            }
            
            if let chunkContentType = "Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8) {
                body.append(chunkContentType)
            }

            body.append(chunk.data)
            if let endOfChunk = "\r\n".data(using: .utf8) {
                body.append(endOfChunk)
            }
        }
        if let closingData = "--\(boundary)--\r\n".data(using: .utf8) {
            body.append(closingData)
        }
        httpRequest.setBody(body)
        
        return httpRequest
    }
}

// MARK: - ObservabilityAuth

public struct ObservabilityAuth {

    let url: URL
    let authKey: String
    let authValue: String
}
