import Foundation

struct EmptyPayload: Codable {
    init() {}
}

struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let success: Bool?
    let message: String
    let data: T?

    var isSuccess: Bool {
        if let success {
            return success
        }
        return AppConstants.API.successCodes.contains(code)
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case success
        case message
        case data
    }

    init(code: Int, success: Bool? = nil, message: String, data: T?) {
        self.code = code
        self.success = success
        self.message = message
        self.data = data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSuccess = try container.decodeIfPresent(Bool.self, forKey: .success)
        success = decodedSuccess

        if let intCode = try? container.decode(Int.self, forKey: .code) {
            code = intCode
        } else if let stringCode = try? container.decode(String.self, forKey: .code), let intCode = Int(stringCode) {
            code = intCode
        } else if decodedSuccess == true {
            code = 200
        } else {
            code = -1
        }

        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        data = try container.decodeIfPresent(T.self, forKey: .data)
    }
}
