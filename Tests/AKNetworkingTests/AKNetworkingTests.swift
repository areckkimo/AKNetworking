import XCTest
@testable import AKNetworking

final class AKNetworkingTests: XCTestCase {
    
    func testRequestWithAPIKey() {
        let akNetworking = AKNetworking()
        let request = FlickrRequest(text: "sum", numberItemsPerPage: "30", currentPage: "1")
        let promis = expectation(description: "Photos count is great than 0")
        akNetworking.send(request) { (result) in
            switch result {
            case .success(let object):
                let photos = object.photos.photo
                if photos.count > 0 {
                    promis.fulfill()
                }else{
                    XCTFail("Photos count is less than 0")
                }
            case .failure(let error):
                XCTFail("Error: \(error.localizedDescription)")
            }
        }
        wait(for: [promis], timeout: 15)
    }

    static var allTests = [
        ("testExample", testRequestWithAPIKey),
    ]
}

struct FlickrRequest: HTTPRequest {
    typealias successResponse = FlickrSuccessResponse
    typealias failureResponse = FlickrFailureResponse
    
    var url: URL = URL(string: "https://api.flickr.com/services/rest")!
    var method: HTTPMethod = .GET
    var parameters: [String : Any] {
        let defaultParameters = ["method": "flickr.photos.search", "content_type":"1", "media":"photos", "format":"json", "nojsoncallback":"1"]
        
        return ["text": text, "per_page": numberItemsPerPage, "page": currentPage].merging(defaultParameters) { (current, new) -> Any in
            new
        }
    }
    var authorizationType: AuthorizationType = .APIKey(key: "api_key", value: "8602dd723449199b716257d4df8b9151", place: .URLQueryParameter)
    var contentType: ContentType = .none
    
    var text: String
    var numberItemsPerPage: String
    var currentPage: String
}

public struct FlickrSuccessResponse : Codable {
    
    public struct Photos: Codable {
        
        public struct Photo: Codable {
            let id: String
            let owner: String
            let secret: String
            let server: String
            let farm: Int
            let title: String
            let ispublic: Int
            let isfriend: Int
            let isfamily: Int
        }
        
        let page: Int
        let pages: Int
        let perpage: Int
        let total: String
        let photo: [Photo]
        
    }
    let photos: Photos
    let stat: String
}

struct FlickrFailureResponse : Codable {
    
}
