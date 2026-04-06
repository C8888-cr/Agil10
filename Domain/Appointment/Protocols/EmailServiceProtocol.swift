//
//  EmailServiceProtocol.swift
//  Agil10.0
//
//  Created by Christiane Roth on 06.04.26.
//


import Foundation

protocol EmailServiceProtocol {
    func sendEmail(to: String, subject: String, body: String)
}