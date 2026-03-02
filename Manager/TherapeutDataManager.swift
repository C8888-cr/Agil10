//
//  TherapeutDataManager.swift
//  Agil10.0
//
//  Created by Christiane Roth on 23.02.26.
//


// TherapeutDataManager.swift
import Foundation
class TherapeutDataManager {
    static let shared = TherapeutDataManager()
    
    // MARK: - Feste UUIDs
    
    // agil Eschersheim
    static let t1Id = UUID(uuidString: "aaaaaaaa-0001-0001-0001-aaaaaaaaaaaa")!
    static let t2Id = UUID(uuidString: "aaaaaaaa-0002-0002-0002-aaaaaaaaaaaa")!
    static let t3Id = UUID(uuidString: "aaaaaaaa-0003-0003-0003-aaaaaaaaaaaa")!
    
    // agil Preungesheim
    static let t4Id = UUID(uuidString: "bbbbbbbb-0001-0001-0001-bbbbbbbbbbbb")!
    static let t5Id = UUID(uuidString: "bbbbbbbb-0002-0002-0002-bbbbbbbbbbbb")!
    static let t6Id = UUID(uuidString: "bbbbbbbb-0003-0003-0003-bbbbbbbbbbbb")!
    
    // agil Langen
    static let t7Id  = UUID(uuidString: "cccccccc-0001-0001-0001-cccccccccccc")!
    static let t8Id  = UUID(uuidString: "cccccccc-0002-0002-0002-cccccccccccc")!
    static let t9Id  = UUID(uuidString: "cccccccc-0003-0003-0003-cccccccccccc")!
    static let t10Id = UUID(uuidString: "cccccccc-0004-0004-0004-cccccccccccc")!
    static let t11Id = UUID(uuidString: "cccccccc-0005-0005-0005-cccccccccccc")!
    
    
    // agil Ostend
    static let t12Id = UUID(uuidString: "dddddddd-0001-0001-0001-dddddddddddd")!
    static let t13Id = UUID(uuidString: "dddddddd-0002-0002-0002-dddddddddddd")!
    static let t14Id = UUID(uuidString: "dddddddd-0003-0003-0003-dddddddddddd")!
    static let t15Id = UUID(uuidString: "dddddddd-0004-0004-0004-dddddddddddd")!
    static let t16Id = UUID(uuidString: "dddddddd-0005-0005-0005-dddddddddddd")!
    
    // agil Dornbusch
    static let t17Id = UUID(uuidString: "eeeeeeee-0001-0001-0001-eeeeeeeeeeee")!
    static let t18Id = UUID(uuidString: "eeeeeeee-0002-0002-0002-eeeeeeeeeeee")!
    static let t19Id = UUID(uuidString: "eeeeeeee-0003-0003-0003-eeeeeeeeeeee")!
    
    // agil Alt-Eschersheim
    static let t20Id = UUID(uuidString: "ffffffff-0001-0001-0001-ffffffffffff")!
    static let t21Id = UUID(uuidString: "ffffffff-0002-0002-0002-ffffffffffff")!
    static let t22Id = UUID(uuidString: "ffffffff-0003-0003-0003-ffffffffffff")!
    
    // MARK: - Alle Therapeuten
    let therapeuten: [Therapeut] = [
        
        // MARK: agil Eschersheim
        Therapeut(
            id: TherapeutDataManager.t1Id,
            firstName: "Anna",
            lastName: "Müller",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t2Id,
            firstName: "Jonas",
            lastName: "Weber",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t3Id,
            firstName: "Laura",
            lastName: "Schmidt",
            praxisId: PraxisDataManager.praxis1Id
        ),
        
        // MARK: agil Preungesheim
        Therapeut(
            id: TherapeutDataManager.t4Id,
            firstName: "Markus",
            lastName: "Klein",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t5Id,
            firstName: "Sophie",
            lastName: "Braun",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t6Id,
            firstName: "Felix",
            lastName: "Wagner",
            praxisId: PraxisDataManager.praxis2Id
        ),
        
        // MARK: agil Langen
        Therapeut(
            id: TherapeutDataManager.t7Id,
            firstName: "Christiane",
            lastName: "Roth",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t8Id,
            firstName: "Kirstin",
            lastName: "Colloseus",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t9Id,
            firstName: "Matthias",
            lastName: "Thomczak",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t10Id,
            firstName: "Nella",
            lastName: "Elkaz",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t11Id,
            firstName: "Sandra",
            lastName: "Korn",
            praxisId: PraxisDataManager.praxis3Id
        ),
        
        // MARK: agil Ostend
        Therapeut(
            id: TherapeutDataManager.t12Id,
            firstName: "Kerstin",
            lastName: "Becker",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t13Id,
            firstName: "Luca",
            lastName: "Leitsch",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t14Id,
            firstName: "Caroline",
            lastName: "Lang",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t15Id,
            firstName: "Christiane",
            lastName: "Roth",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t16Id,
            firstName: "Ruben",
            lastName: "Hoffmann",
            praxisId: PraxisDataManager.praxis4Id
        ),
        
        // MARK: agil Dornbusch
        Therapeut(
            id: TherapeutDataManager.t17Id,
            firstName: "Lisa",
            lastName: "Neumann",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t18Id,
            firstName: "Ben",
            lastName: "Zimmermann",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t19Id,
            firstName: "Jana",
            lastName: "Krause",
            praxisId: PraxisDataManager.praxis5Id
        ),
        
        // MARK: agil Alt-Eschersheim
        Therapeut(
            id: TherapeutDataManager.t20Id,
            firstName: "Max",
            lastName: "Hartmann",
            praxisId: PraxisDataManager.praxis6Id
        ),
        Therapeut(
            id: TherapeutDataManager.t21Id,
            firstName: "Eva",
            lastName: "Lange",
            praxisId: PraxisDataManager.praxis6Id
        ),
        Therapeut(
            id: TherapeutDataManager.t22Id,
            firstName: "Lukas",
            lastName: "Bauer",
            praxisId: PraxisDataManager.praxis6Id
        )
    ]
    
    private init() {}
    
    // MARK: - Helper Funktionen
    
    /// Alle Therapeuten einer Praxis
    func getTherapeutenForPraxis(_ praxisId: UUID) -> [Therapeut] {
        therapeuten.filter { $0.praxisId == praxisId }
    }
    
    /// Therapeut by ID
    func getTherapeut(by id: UUID) -> Therapeut? {
        therapeuten.first { $0.id == id }
    }
    
    /// Name by ID
    func getTherapeutName(for id: UUID?) -> String {
        guard let id = id,
              let therapeut = getTherapeut(by: id) else {
            return "Kein Therapeut ausgewählt"
        }
        return therapeut.fullName
    }
}
