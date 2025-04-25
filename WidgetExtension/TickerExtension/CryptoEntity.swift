//
//  CryptoEntity.swift
//  Coin
//
//  Created by Nikita Verkhovin on 24.04.2025.
//

import AppIntents

struct CryptoEntity: AppEntity {
    let id: String
    let symbol: String
    let name: String
    var logo: Data?
    
    static let bitcoin: CryptoEntity = CryptoEntity(id: "bitcoin@bitcoin", symbol: "BTC", name: "Bitcoin", logo: UIImage(named: "Bitcoin")?.pngData())
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Crypto"
    static var defaultQuery = CryptoQuery()
     
    var displayRepresentation: DisplayRepresentation {
        if logo != nil {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(symbol)",
                image: DisplayRepresentation.Image(data: logo!, isTemplate: false)
            )
        } else {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(symbol)"
            )
        }
    }
    
    static func fromCryptoCodable(_ c: CryptoCodable) -> CryptoEntity {
        self.init(id: c._id, symbol: c.symbol, name: c.name, logo: c.logoData)
    }
}

struct CryptoQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [CryptoEntity] {
        var cryptos = try await ApiClient.shared.cryptos().filter { identifiers.contains($0._id) }
        cryptos = await loadLogoData(cryptos)
        return cryptos.map(CryptoEntity.fromCryptoCodable)
    }
   
    func entities(matching search: String) async throws -> IntentItemCollection<CryptoEntity> {
        return try await entitiesWithLogo("Other cryptos", search)
    }
    
    func suggestedEntities() async throws -> IntentItemCollection<CryptoEntity> {
        return try await entitiesWithLogo("Top cryptos")
    }
    
    func defaultResult() async -> [CryptoEntity]? {
        return [CryptoEntity.bitcoin]
    }
    
    private func entitiesWithLogo(_ title: LocalizedStringResource = "", _ search: String = "") async throws -> IntentItemCollection<CryptoEntity> {
        let needle = search.trimmingCharacters(in: .whitespaces)
        if needle == "" && search != "" {
            return IntentItemCollection(sections: [])
        }
        let allCryptos = try await ApiClient.shared.cryptos()
        var cryptos = Array((search.isEmpty ? allCryptos : allCryptos.filter { "\($0.name) \($0.symbol)".localizedCaseInsensitiveContains(needle) }).prefix(10))
        cryptos = await loadLogoData(cryptos)
        
        return IntentItemCollection(sections: [
            IntentItemSection(title, items: cryptos.map(CryptoEntity.fromCryptoCodable))
        ])
    }
    
    private func loadLogoData(_ cryptos: [CryptoCodable]) async -> [CryptoCodable] {
        var items = cryptos
        await withTaskGroup(of: Void.self) { group in
            for i in items.indices {
                group.addTask {
                    // TODO: add ?ver= with app version
                    let image = await AppService.shared.downloadImage(url: "https://price.coin.space/logo/\(items[i].logo!)")
                    items[i].logoData = image?.pngData()
                }
            }
        }
        return items
    }
}
