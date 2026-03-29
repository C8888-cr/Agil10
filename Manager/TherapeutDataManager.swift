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

    // agil Eschersheim (praxis1) — 8 Therapeuten
    static let t1Id  = UUID(uuidString: "aaaaaaaa-0001-0001-0001-aaaaaaaaaaaa")!
    static let t2Id  = UUID(uuidString: "aaaaaaaa-0002-0002-0002-aaaaaaaaaaaa")!
    static let t3Id  = UUID(uuidString: "aaaaaaaa-0003-0003-0003-aaaaaaaaaaaa")!
    static let t4Id  = UUID(uuidString: "aaaaaaaa-0004-0004-0004-aaaaaaaaaaaa")!
    static let t5Id  = UUID(uuidString: "aaaaaaaa-0005-0005-0005-aaaaaaaaaaaa")!
    static let t6Id  = UUID(uuidString: "aaaaaaaa-0006-0006-0006-aaaaaaaaaaaa")!
    static let t7Id  = UUID(uuidString: "aaaaaaaa-0007-0007-0007-aaaaaaaaaaaa")!
    static let t8Id  = UUID(uuidString: "aaaaaaaa-0008-0008-0008-aaaaaaaaaaaa")!

    // agil Preungesheim (praxis2) — 8 Therapeuten
    static let t9Id  = UUID(uuidString: "bbbbbbbb-0001-0001-0001-bbbbbbbbbbbb")!
    static let t10Id = UUID(uuidString: "bbbbbbbb-0002-0002-0002-bbbbbbbbbbbb")!
    static let t11Id = UUID(uuidString: "bbbbbbbb-0003-0003-0003-bbbbbbbbbbbb")!
    static let t12Id = UUID(uuidString: "bbbbbbbb-0004-0004-0004-bbbbbbbbbbbb")!
    static let t13Id = UUID(uuidString: "bbbbbbbb-0005-0005-0005-bbbbbbbbbbbb")!
    static let t14Id = UUID(uuidString: "bbbbbbbb-0006-0006-0006-bbbbbbbbbbbb")!
    static let t15Id = UUID(uuidString: "bbbbbbbb-0007-0007-0007-bbbbbbbbbbbb")!
    static let t16Id = UUID(uuidString: "bbbbbbbb-0008-0008-0008-bbbbbbbbbbbb")!

    // agil Langen (praxis3) — 6 Therapeuten
    static let t17Id = UUID(uuidString: "cccccccc-0001-0001-0001-cccccccccccc")!
    static let t18Id = UUID(uuidString: "cccccccc-0002-0002-0002-cccccccccccc")!
    static let t19Id = UUID(uuidString: "cccccccc-0003-0003-0003-cccccccccccc")!
    static let t20Id = UUID(uuidString: "cccccccc-0004-0004-0004-cccccccccccc")!
    static let t21Id = UUID(uuidString: "cccccccc-0005-0005-0005-cccccccccccc")!
    static let t22Id = UUID(uuidString: "cccccccc-0006-0006-0006-cccccccccccc")!

    // agil Ostend (praxis4) — 6 Therapeuten
    static let t23Id = UUID(uuidString: "dddddddd-0001-0001-0001-dddddddddddd")!
    static let t24Id = UUID(uuidString: "dddddddd-0002-0002-0002-dddddddddddd")!
    static let t25Id = UUID(uuidString: "dddddddd-0003-0003-0003-dddddddddddd")!
    static let t26Id = UUID(uuidString: "dddddddd-0004-0004-0004-dddddddddddd")!
    static let t27Id = UUID(uuidString: "dddddddd-0005-0005-0005-dddddddddddd")!
    static let t28Id = UUID(uuidString: "dddddddd-0006-0006-0006-dddddddddddd")!

    // agil Dornbusch (praxis5) — 8 Therapeuten
    static let t29Id = UUID(uuidString: "eeeeeeee-0001-0001-0001-eeeeeeeeeeee")!
    static let t30Id = UUID(uuidString: "eeeeeeee-0002-0002-0002-eeeeeeeeeeee")!
    static let t31Id = UUID(uuidString: "eeeeeeee-0003-0003-0003-eeeeeeeeeeee")!
    static let t32Id = UUID(uuidString: "eeeeeeee-0004-0004-0004-eeeeeeeeeeee")!
    static let t33Id = UUID(uuidString: "eeeeeeee-0005-0005-0005-eeeeeeeeeeee")!
    static let t34Id = UUID(uuidString: "eeeeeeee-0006-0006-0006-eeeeeeeeeeee")!
    static let t35Id = UUID(uuidString: "eeeeeeee-0007-0007-0007-eeeeeeeeeeee")!
    static let t36Id = UUID(uuidString: "eeeeeeee-0008-0008-0008-eeeeeeeeeeee")!

    // agil Alt-Eschersheim (praxis6) — 6 Therapeuten
    static let t37Id = UUID(uuidString: "ffffffff-0001-0001-0001-ffffffffffff")!
    static let t38Id = UUID(uuidString: "ffffffff-0002-0002-0002-ffffffffffff")!
    static let t39Id = UUID(uuidString: "ffffffff-0003-0003-0003-ffffffffffff")!
    static let t40Id = UUID(uuidString: "ffffffff-0004-0004-0004-ffffffffffff")!
    static let t41Id = UUID(uuidString: "ffffffff-0005-0005-0005-ffffffffffff")!
    static let t42Id = UUID(uuidString: "ffffffff-0006-0006-0006-ffffffffffff")!
    
    // MARK: - Alle Therapeuten
    let therapeuten: [Therapeut] = [
        
        // MARK: agil Eschersheim
        Therapeut(
            id: TherapeutDataManager.t1Id,
            firstName: "Martin",
            lastName: "Gerlicki",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t2Id,
            firstName: "Alexander",
            lastName: "Koetter",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t3Id,
            firstName: "Phillip",
            lastName: "Schneider",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t4Id,
            firstName: "Daniela",
            lastName: "Uvericht",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t5Id,
            firstName: "Lisa",
            lastName: "Hahn",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t6Id,
            firstName: "Kristina",
            lastName: "Bender",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t7Id,
            firstName: "Jelena",
            lastName: "Trivic",
            praxisId: PraxisDataManager.praxis1Id
        ),
        Therapeut(
            id: TherapeutDataManager.t8Id,
            firstName: "Ulrike",
            lastName: "Kozalla",
            praxisId: PraxisDataManager.praxis1Id
        ),
        
        
        
        // MARK: agil Preungesheim
        Therapeut(
            id: TherapeutDataManager.t9Id,
            firstName: "Burak",
            lastName: "Eren",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t10Id,
            firstName: "Andrea",
            lastName: "Lakemeier",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t11Id,
            firstName: "Anke",
            lastName: "Nonhebel",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t12Id,
            firstName: "Kathi",
            lastName: "Offelmann",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t13Id,
            firstName: "Kevin",
            lastName: "Meder",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t14Id,
            firstName: "Noah",
            lastName: "Braun",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t15Id,
            firstName: "Florian",
            lastName: "Liss",
            praxisId: PraxisDataManager.praxis2Id
        ),
        Therapeut(
            id: TherapeutDataManager.t16Id,
            firstName: "Fabian",
            lastName: "Kern",
            praxisId: PraxisDataManager.praxis2Id
        ),
        
        // MARK: agil Langen
        Therapeut(
            id: TherapeutDataManager.t17Id,
            firstName: "Matthias",
            lastName: "Thomczak",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t18Id,
            firstName: "Kirstin",
            lastName: "Colloseus",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t19Id,
            firstName: "Christiane",
            lastName: "Roth",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t20Id,
            firstName: "Nella",
            lastName: "Elkaz",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t21Id,
            firstName: "Sandra",
            lastName: "Korn",
            praxisId: PraxisDataManager.praxis3Id
        ),
        Therapeut(
            id: TherapeutDataManager.t21Id,
            firstName: "Jana",
            lastName: "Wieclawic",
            praxisId: PraxisDataManager.praxis3Id
        ),
        
        // MARK: agil Ostend
        Therapeut(
            id: TherapeutDataManager.t22Id,
            firstName: "Kerstin",
            lastName: "Becker",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t23Id,
            firstName: "Luca",
            lastName: "Leitsch",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t24Id,
            firstName: "Caroline",
            lastName: "Lang",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t25Id,
            firstName: "Christiane",
            lastName: "Roth",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t26Id,
            firstName: "Ruben",
            lastName: "Hoffmann",
            praxisId: PraxisDataManager.praxis4Id
        ),
        Therapeut(
            id: TherapeutDataManager.t27Id,
            firstName: "Amina",
            lastName: "Daberkow",
            praxisId: PraxisDataManager.praxis4Id
        ),
        
        // MARK: agil Dornbusch
        Therapeut(
            id: TherapeutDataManager.t28Id,
            firstName: "Nicole",
            lastName: "Weil",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t29Id,
            firstName: "Julia",
            lastName: "Will",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t28Id,
            firstName: "Marcel",
            lastName: "Minet",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t29Id,
            firstName: "Lea",
            lastName: "Gutmann",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t30Id,
            firstName: "Eric",
            lastName: "Mineif",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t31Id,
            firstName: "Betina",
            lastName: "Vulyanova",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t32Id,
            firstName: "Maren",
            lastName: "Haverland",
            praxisId: PraxisDataManager.praxis5Id
        ),
        Therapeut(
            id: TherapeutDataManager.t33Id,
            firstName: "Tim-Phillip",
            lastName: "Koloczek",
            praxisId: PraxisDataManager.praxis5Id
        ),
        
        // MARK: agil Alt-Eschersheim
        Therapeut(
            id: TherapeutDataManager.t34Id,
            firstName: "Wolf Jörg",
            lastName: "Wohnhaut",
            praxisId: PraxisDataManager.praxis6Id
        ),
        Therapeut(
            id: TherapeutDataManager.t35Id,
            firstName: "Stefan",
            lastName: "Wolfenstädter",
            praxisId: PraxisDataManager.praxis6Id
        ),
        Therapeut(
            id: TherapeutDataManager.t36Id,
            firstName: "Nikola",
            lastName: "Simikj",
            praxisId: PraxisDataManager.praxis6Id
        ),
        Therapeut(
            id: TherapeutDataManager.t37Id,
            firstName: "Ann-Katrin",
            lastName: "Bunzel",
            praxisId: PraxisDataManager.praxis6Id
        ),
        Therapeut(
            id: TherapeutDataManager.t38Id,
            firstName: "Niclas",
            lastName: "Bohm",
            praxisId: PraxisDataManager.praxis6Id
        ),
        Therapeut(
            id: TherapeutDataManager.t39Id,
            firstName: "Tibor",
            lastName: "Blummer",
            praxisId: PraxisDataManager.praxis6Id
        ),
        
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
