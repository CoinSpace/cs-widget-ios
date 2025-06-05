//
//  CurrencyEntity.swift
//  Coin
//
//  Created by Nikita Verkhovin on 24.04.2025.
//

import AppIntents

enum CurrencyEntity: String, AppEnum {
    case AED = "AED"
    case ARS = "ARS"
    case AUD = "AUD"
    case BDT = "BDT"
    case BHD = "BHD"
    case BMD = "BMD"
    case BRL = "BRL"
    case CAD = "CAD"
    case CHF = "CHF"
    case CLP = "CLP"
    case CNY = "CNY"
    case CZK = "CZK"
    case DKK = "DKK"
    case EUR = "EUR"
    case GBP = "GBP"
    case HKD = "HKD"
    case HUF = "HUF"
    case IDR = "IDR"
    case ILS = "ILS"
    case INR = "INR"
    case JPY = "JPY"
    case KRW = "KRW"
    case KWD = "KWD"
    case LKR = "LKR"
    case MMK = "MMK"
    case MXN = "MXN"
    case MYR = "MYR"
    case NGN = "NGN"
    case NOK = "NOK"
    case NZD = "NZD"
    case PHP = "PHP"
    case PKR = "PKR"
    case PLN = "PLN"
    case RUB = "RUB"
    case SAR = "SAR"
    case SEK = "SEK"
    case SGD = "SGD"
    case THB = "THB"
    case TRY = "TRY"
    case TWD = "TWD"
    case UAH = "UAH"
    case USD = "USD"
    case VEF = "VEF"
    case VND = "VND"
    case ZAR = "ZAR"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Currency"

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .AED: "AED",
        .ARS: "ARS",
        .AUD: "AUD",
        .BDT: "BDT",
        .BHD: "BHD",
        .BMD: "BMD",
        .BRL: "BRL",
        .CAD: "CAD",
        .CHF: "CHF",
        .CLP: "CLP",
        .CNY: "CNY",
        .CZK: "CZK",
        .DKK: "DKK",
        .EUR: "EUR",
        .GBP: "GBP",
        .HKD: "HKD",
        .HUF: "HUF",
        .IDR: "IDR",
        .ILS: "ILS",
        .INR: "INR",
        .JPY: "JPY",
        .KRW: "KRW",
        .KWD: "KWD",
        .LKR: "LKR",
        .MMK: "MMK",
        .MXN: "MXN",
        .MYR: "MYR",
        .NGN: "NGN",
        .NOK: "NOK",
        .NZD: "NZD",
        .PHP: "PHP",
        .PKR: "PKR",
        .PLN: "PLN",
        .RUB: "RUB",
        .SAR: "SAR",
        .SEK: "SEK",
        .SGD: "SGD",
        .THB: "THB",
        .TRY: "TRY",
        .TWD: "TWD",
        .UAH: "UAH",
        .USD: "USD",
        .VEF: "VEF",
        .VND: "VND",
        .ZAR: "ZAR",
    ]
}
