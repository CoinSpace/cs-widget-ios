//
//  CryptoEntity.swift
//  Coin
//
//  Created by Nikita Verkhovin on 24.04.2025.
//

import AppIntents

struct CryptoEntity: AppEntity {
    let id: String
    let cryptoId: String
    let symbol: String
    let name: String
    var image: UIImage?
    
    static let bitcoin: CryptoEntity = CryptoEntity(id: "bitcoin", cryptoId: "bitcoin@bitcoin", symbol: "BTC", name: "Bitcoin", image: UIImage(named: "Bitcoin"))
    static let ethereum: CryptoEntity = CryptoEntity(id: "ethereum", cryptoId: "ethereum@ethereum", symbol: "ETH", name: "Ethereum", image: UIImage(named: "Ethereum"))
    static let solana: CryptoEntity = CryptoEntity(id: "solana", cryptoId: "solana@solana", symbol: "SOL", name: "Solana", image: UIImage(named: "Solana"))
    static let dogecoin: CryptoEntity = CryptoEntity(id: "dogecoin", cryptoId: "dogecoin@dogecoin", symbol: "DOGE", name: "Dogecoin", image: UIImage(named: "Dogecoin"))
    static let litecoin: CryptoEntity = CryptoEntity(id: "litecoin", cryptoId: "litecoin@litecoin", symbol: "LTC", name: "Litecoin", image: UIImage(named: "Litecoin"))
    static let monero: CryptoEntity = CryptoEntity(id: "monero", cryptoId: "monero@monero", symbol: "XMR", name: "Monero", image: UIImage(named: "Monero"))
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Crypto"
    static var defaultQuery = CryptoQuery()
     
    var displayRepresentation: DisplayRepresentation {
        if image != nil {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(symbol)",
                image: DisplayRepresentation.Image(data: (image?.pngData())!, isTemplate: false)
            )
        } else {
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(symbol)"
            )
        }
    }
    
    static func fromCryptoCodable(_ c: CryptoCodable) -> CryptoEntity {
        self.init(id: c.asset, cryptoId: c._id, symbol: c.symbol, name: c.name, image: c.image)
    }
}

struct CryptoQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [CryptoEntity] {
        var cryptos = try await ApiClient.shared.cryptos().filter { identifiers.contains($0.asset) }
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
        return [
            CryptoEntity.bitcoin,
            CryptoEntity.ethereum,
            CryptoEntity.solana,
            CryptoEntity.dogecoin,
            CryptoEntity.litecoin,
            CryptoEntity.monero
        ]
    }
    
    func topCryptos(_ size: Int) async throws -> [CryptoEntity]? {
        var cryptos = Array(try await ApiClient.shared.cryptos().prefix(size))
        cryptos = await loadLogoData(cryptos)
        return cryptos.map(CryptoEntity.fromCryptoCodable)
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
        var images = Array<UIImage?>(repeating: nil, count: items.count)
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for i in items.indices {
                group.addTask {
                    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]!
                    let image = await AppService.shared.downloadImage(url: "https://price.coin.space/logo/\(items[i].logo!)?ver=\(version)")
                    return (i, image)
                }
            }
            for await (index, image) in group {
                images[index] = image
            }
        }
        for i in items.indices {
            items[i].image = images[i]
        }
        return items
    }
}
