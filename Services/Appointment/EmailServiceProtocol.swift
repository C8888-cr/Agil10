//
//  EmailServiceProtocol.swift
//  Agil
//
//  Created by Christiane Roth on 25.11.25.
//


//
//  EmailService.swift
//  Agil7.0
//
//  Created by Christiane Roth on 05.10.25.
//

// Features/Appointments/Services/EmailService.swift
import UIKit
import Foundation
protocol EmailServiceProtocol {
    func sendEmail(to: String, subject: String, body: String)
}
class EmailService: EmailServiceProtocol {
    func sendEmail(to: String, subject: String, body: String) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
