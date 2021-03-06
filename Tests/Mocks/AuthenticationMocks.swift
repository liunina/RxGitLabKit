//
//  AuthenticationMocks.swift
//  RxGitLabKit-iOSTests
//
//  Created by Dagy Tran on 31/10/2018.
//

import Foundation

struct AuthenticationMocks {
  static let unauthorizedResponseData = """
{
  "message": "401 Unauthorized"
}
""".data()

  static let forbiddenResponseData = """
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
""".data()

  static let oAuthResponseData = """
{"access_token":"5e8672700e931c97830b4casdfe065de35c8b63c913df262a18b915e31138218","token_type":"bearer","refresh_token":"96pl81b5d7dd524dc3b96c88c3cd3c62365769b9bef2b11c9995b2b5526c584","scope":"api","created_at":1534516936}
""".data()

  static let username = "tranaduc"
  static let password = "gvLBqDJkpAUr6s2"
  static let oAuthToken = "e379c3dd992dfb8043db912bb8ad6643130848184edad33358029a3176cabaec"

}
