import Foundation

enum PhoneAttributionCatalog {
    static func load(bundle: Bundle = .main) -> [PhoneAttribution] {
        guard let url = bundle.url(forResource: "phone", withExtension: "xml"),
              let parser = XMLParser(contentsOf: url) else {
            return []
        }

        let delegate = PhoneAttributionXMLParserDelegate()
        parser.delegate = delegate

        guard parser.parse() else {
            return []
        }

        return mergeAndSort(primary: delegate.attributions, overlay: [])
    }

    static func mergeAndSort(
        primary: [PhoneAttribution],
        overlay: [PhoneAttribution]
    ) -> [PhoneAttribution] {
        var mergedByCode: [Int: PhoneAttribution] = [:]

        primary.forEach { item in
            mergedByCode[item.code] = item
        }

        overlay.forEach { item in
            if let existing = mergedByCode[item.code] {
                mergedByCode[item.code] = existing.merged(with: item)
            } else {
                mergedByCode[item.code] = item
            }
        }

        let localeIdentifier = UserPreferences.currentLocale
        return mergedByCode.values.sorted {
            $0.displayName(locale: localeIdentifier)
                .localizedCaseInsensitiveCompare($1.displayName(locale: localeIdentifier)) == .orderedAscending
        }
    }
}

private final class PhoneAttributionXMLParserDelegate: NSObject, XMLParserDelegate {
    private(set) var attributions: [PhoneAttribution] = []

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName == "Attribution",
              let codeText = attributeDict["Code"],
              let code = Int(codeText) else {
            return
        }

        attributions.append(
            PhoneAttribution(
                id: code,
                code: code,
                flag: attributeDict["Flag"] ?? "",
                name: attributeDict["Name"] ?? ""
            )
        )
    }
}
