//
//  SignUpRequest.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


// Domain/Auth/SignUpRequest.swift
import Foundation

struct SignUpRequest {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let praxisId: UUID?
}