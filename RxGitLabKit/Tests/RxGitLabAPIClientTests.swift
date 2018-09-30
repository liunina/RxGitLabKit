//
//  RxGitLabAPIClientTests.swift
//  RxGitLabKit-iOSTests
//
//  Created by Dagy Tran on 20/08/2018.
//

import Foundation
import XCTest
import RxGitLabKit
import RxSwift

class RxGitLabAPIClientTests: XCTestCase {
  
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  } ()
  
  private var client: RxGitLabAPIClient!
  
  private let hostURL = URL(string: "test.gitlab.com")!
  
  
  override func setUp() {
    super.setUp()
//    URLProtocol.registerClass(MockURLProtocol.self)
    client = RxGitLabAPIClient(with: hostURL, using: session)

    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testTokens() {
    let host = "gitlab.com"
    let hostURL = URL(string: host)!
    let oAuthToken = "oAuthToken"
    let client = RxGitLabAPIClient(with: hostURL, oAuthToken: oAuthToken)
    MockURLProtocol.requestHandler = { request in
      
      XCTAssertNotNil(request.url)
      XCTAssertTrue((request.url?.pathComponents.contains(host))!)
      
      return (HTTPURLResponse(), RxGitLabApiClientMocks.tokenDataMock)
    }
    
    
  }
  
  func testHost() {
    let bag = DisposeBag()

    let host = "localhost"
    
    let client = RxGitLabAPIClient(with: URL(string: host)!)
    MockURLProtocol.requestHandler = { request in
      
      XCTAssertNotNil(request.url)
      XCTAssertTrue((request.url?.pathComponents.contains(host))!)
      
      return (HTTPURLResponse(), RxGitLabApiClientMocks.tokenDataMock)
    }
    
    let authentication = client.authentication.authenticate(username: "username", password: "password")
    let expectation = XCTestExpectation(description: "response")
    authentication.subscribe { event in
      print(event)
      expectation.fulfill()
    }
      .disposed(by: bag)
    wait(for: [expectation], timeout: 10)
    
  }
  
  func testAuthentication() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    let bag = DisposeBag()

    let username = "username"
    let password = "password"
    
//    XCTAssert(client.test == "tesst")
    
    
    
    MockURLProtocol.requestHandler = { request in
      guard let bodyStream = request.httpBodyStream, let bodyDict = try? JSONSerialization.jsonObject(with: bodyStream.readData(), options: []) as! [String: String] else {
        XCTFail("Can't read the body of the request.")
        let response = HTTPURLResponse(url: self.hostURL, statusCode: 401, httpVersion: "1.1", headerFields: nil)!
        
        return (response, GeneralMocks.errorJSONData)
      }
      XCTAssertNotNil(bodyDict["username"])
      XCTAssertNotNil(bodyDict["password"])
      XCTAssertEqual(username, bodyDict["username"])
      XCTAssertEqual(password, bodyDict["password"])
      XCTAssertNotEqual(password, bodyDict["username"])
      
      return (HTTPURLResponse(), RxGitLabApiClientMocks.tokenDataMock)
    }
    
    let authentication = client.authentication.authenticate(username: username, password: password)
    let expectation = XCTestExpectation(description: "response")
    authentication.subscribe { event in
      print(event)
      expectation.fulfill()
    }.disposed(by: bag)
    wait(for: [expectation], timeout: 1)
  }
  
  func testAuthentication2() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    let host = "gitlab.fel.cvut.cz"  
    
    let client = RxGitLabAPIClient(with: URL(string: host)!)
    
    
    let bag = DisposeBag()
    
    let username = "tranaduc"
    let password = "nV4-ubr-M8V-LFx"
    
    //    XCTAssert(client.test == "tesst")
  
    let authentication = client.authentication.authenticate(username: username, password: password)
    let expectation = XCTestExpectation(description: "response")
    authentication.subscribe { event in
      print(event)
      expectation.fulfill()
      }.disposed(by: bag)
    wait(for: [expectation], timeout: 1)
  }
  
  func testPagination() {
    let host = "https://gitlab.fel.cvut.cz"
    let bag = DisposeBag()
    
    let username = "tranaduc"
    let password = "nV4-ubr-M8V-LFx"
    let client = RxGitLabAPIClient(with: URL(string: host)!)
    let expectation = XCTestExpectation(description: "response")

    client.getOAuthToken(username: username, password: password)
    client.authentication.authenticate(username: username, password: password).subscribe({event in
      print(event)
      guard let authentication = event.element else { return }
      client.oAuthToken.onNext(authentication.oAuthToken)
      let paginator = client.users.getUsers2()
      paginator.load().subscribe { event in
          print(event)
        print(paginator)
        expectation.fulfill()
      }
    })

    
    wait(for: [expectation], timeout: 100)

  }
  
  func testPagination2() {
    let host = "https://gitlab.fel.cvut.cz"
    let bag = DisposeBag()
    
    let username = "tranaduc"
    let password = "nV4-ubr-M8V-LFx"
    let client = RxGitLabAPIClient(with: URL(string: host)!)
    let expectation = XCTestExpectation(description: "response")
    
    client.getOAuthToken(username: username, password: password)
    
    client.users.getUsers()
    client.authentication.authenticate(username: username, password: password)
      .subscribe({event in
//      print(event)
      guard let authentication = event.element else { return }
      client.oAuthToken.onNext(authentication.oAuthToken)
      
//      paginator.page.value = 1
//      paginator.page.value = 10
    })
    
    let paginator = client.users.getUsers2(page: 1, perPage: 10)
    paginator.list.asObservable()
      .filter({ !$0.isEmpty })
//      .sample(client.oAuthToken.asObservable().filter { $0 != nil})
      .subscribe (onNext: { users in
        print("users")
        for user in users {
          print(user.username)
        }

        if users.count < 20 {
//          paginator.loadNextPage()
          paginator.page.value = 3
        } else {
          expectation.fulfill()
        }
      }, onError: { error in
        print(error)
      })
//      .disposed(by: bag)

    
    paginator.oAuthToken.asObservable()
    .filter {$0 != nil}
    .subscribe(onNext: {_ in
      paginator.loadNextPage()
//      paginator.page.value = 2
    })
//    .disposed(by: bag)
    
    wait(for: [expectation], timeout: 100)
    
  }
  
  
  func testUsersDecode() {
    let users = """
[{"id":2989,"name":"Bc. Viktor Jarolímek","username":"jarolvik","state":"active","avatar_url":"https://secure.gravatar.com/avatar/8acdedb448e7e8e5ec8a271590ebbd25?s=80\\u0026d=identicon","web_url":"https://gitlab.fel.cvut.cz/jarolvik"},{"id":2988,"name":"Radka Hošková","username":"hoskorad","state":"active","avatar_url":"https://secure.gravatar.com/avatar/84bb3f80bca53aaab1e825ed215abf35?s=80\\u0026d=identicon","web_url":"https://gitlab.fel.cvut.cz/hoskorad"},{"id":2987,"name":"Jan Havránek","username":"havraja6","state":"active","avatar_url":"https://secure.gravatar.com/avatar/6ae895a7c774ae46c97843cb5ffd577a?s=80\\u0026d=identicon","web_url":"https://gitlab.fel.cvut.cz/havraja6"},{"id":2986,"name":"Josef Struž","username":"struzjos","state":"active","avatar_url":"https://secure.gravatar.com/avatar/2c31e769e406915add2a29d375f8116f?s=80\\u0026d=identicon","web_url":"https://gitlab.fel.cvut.cz/struzjos"},{"id":2985,"name":"prof. Ing. Jiří Žára CSc.","username":"zara","state":"active","avatar_url":"https://secure.gravatar.com/avatar/351fffb599f48ae1fd2f15eb7659d64e?s=80\\u0026d=identicon","web_url":"https://gitlab.fel.cvut.cz/zara"}]
"""
    
    let data = users.data(using: .utf8)!
    
    let decoder = JSONDecoder()
    if let users = try? decoder.decode([User].self, from: data) {
      for user in users {
        print(user)
      }
    } else {
      print("error")
    }
    
    
  }
  
  
  func testUserDecode() {
    let user = """
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": null,
  "location": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": ""
}
"""
    let data = user.data(using: .utf8)!
    
    let decoder = JSONDecoder()
    if let user = try? decoder.decode(User.self, from: data) {
      print(user)
    } else {
      print("error")
    }
    
    
  }
  
}