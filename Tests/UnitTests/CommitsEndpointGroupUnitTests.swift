//
//  CommitsEndpointGroupTests.swift
//  RxGitLabKit-iOSTests
//
//  Created by Dagy Tran on 18/10/2018.
//

import XCTest
@testable import RxGitLabKit
import RxSwift
import RxBlocking
import RxTest

class CommitsEndpointGroupUnitTests: EndpointGroupUnitTestCase {

  func testGetCommits() {
    let request = URLRequest(url: hostAPIURL.appendingPathComponent(CommitsEndpointGroup.Endpoints.commits(projectID: CommitsMocks.mockProjectID).url))
    mockSession.urlResponse = GeneralMocks.successHttpURLResponse(request: request)
    mockSession.nextData = CommitsMocks.twoCommitsData
    let paginator = client.commits.getCommits(projectID: CommitsMocks.mockProjectID)
    let result = paginator[1]
      .filter {!$0.isEmpty}
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
      XCTAssertEqual(mockSession.lastURL?.pathComponents[1...6].joined(separator: "/"),"api/v4/projects/12345/repository/commits")
      XCTAssertNotNil(mockSession.lastURL)
      XCTAssertEqual(URLComponents(url: mockSession.lastURL!, resolvingAgainstBaseURL: false)!.path, "\(RxGitLabAPIClient.apiVersionURLString)\(CommitsEndpointGroup.Endpoints.commits(projectID: CommitsMocks.mockProjectID).url)")

      XCTAssertEqual(element.count, 1)
      let commits = element.first!
      XCTAssertEqual(commits.count, 2)
      let firstCommit = commits.first!
      let secondCommit = commits.last!
      XCTAssertNotEqual(firstCommit, secondCommit)
      XCTAssertEqual(firstCommit.id, "ed899a2f4b50b4370feeea94676502b42383c746")
      XCTAssertEqual(firstCommit.shortId, "ed899a2f4b5")
      XCTAssertEqual(firstCommit.authorName, "Dmitriy Zaporozhets")
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testGetCommit() {
    mockSession.nextData = CommitsMocks.singleCommitResponseData
    let commit = client.commits.getCommit(projectID: CommitsMocks.mockProjectID, sha: "ed899a2f4b50b4370feeea94676502b42383c746")
    let result = commit.toBlocking().materialize()

    switch result {
    case .completed(elements: let element):
    XCTAssertEqual(mockSession.lastURL?.pathComponents[1...7].joined(separator: "/"),"api/v4/projects/12345/repository/commits/ed899a2f4b50b4370feeea94676502b42383c746")
      
      XCTAssertEqual(element.count, 1)
      let commit = element.first!
      XCTAssertEqual(commit.id, "6104942438c14ec7bd21c6cd5bd995272b3faff6")
      XCTAssertEqual(commit.shortId, "6104942438c")
      XCTAssertEqual(commit.title, "Sanitize for network graph")
      XCTAssertEqual(commit.authorName, "randx")
      XCTAssertEqual(commit.authorEmail, "dmitriy.zaporozhets@gmail.com")
      XCTAssertEqual(commit.committerName, "Dmitriy")
      XCTAssertEqual(commit.committerEmail, "dmitriy.zaporozhets@gmail.com")
      XCTAssertEqual(commit.message, "Sanitize for network graph")
      XCTAssertNotNil(commit.parentIds)
      XCTAssertEqual(commit.parentIds!.count, 1)
      XCTAssertEqual(commit.parentIds!.first!, "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba")
      XCTAssertEqual(commit.status, "running")

      XCTAssertNotNil(commit.lastPipeline)
      let pipeline = commit.lastPipeline!
      XCTAssertEqual(pipeline.id, 8)
      XCTAssertEqual(pipeline.ref, "master")
      XCTAssertEqual(pipeline.sha, "2dc6aa325a317eda67812f05600bdf0fcdc70ab0")
      XCTAssertEqual(pipeline.status, "created")

      XCTAssertNotNil(commit.stats)
      let stats = commit.stats!
      XCTAssertEqual(stats.additions, 15)
      XCTAssertEqual(stats.deletions, 10)
      XCTAssertEqual(stats.total, 25)

      let timeZone = TimeZone(secondsFromGMT: 3*3600)
      let components = DateComponents(calendar: calendar, timeZone: timeZone, year: 2012, month: 9, day: 20, hour: 9, minute: 6, second: 12)
      let date = calendar.date(from: components)!

      XCTAssertEqual(commit.createdAt, date)
      XCTAssertEqual(commit.authoredDate, date)
      XCTAssertEqual(commit.committedDate, date)
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testCreateCommit() {
    mockSession.nextData = CommitsMocks.newCommitResponseData
    let projectID = CommitsMocks.mockProjectID
    let commit = client.commits.createCommit(projectID: projectID, newCommit: CommitsMocks.newCommitMock)
    let result = commit
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
      XCTAssertEqual(mockSession.lastURL?.pathComponents[1...6].joined(separator: "/"),"api/v4/projects/12345/repository/commits")
      XCTAssertEqual(element.count, 1)
      let commit = element.first!

      XCTAssertNotNil(mockSession.lastURL)
      XCTAssertEqual(URLComponents(url: mockSession.lastURL!, resolvingAgainstBaseURL: false)!.path, "\(RxGitLabAPIClient.apiVersionURLString)\(CommitsEndpointGroup.Endpoints.commits(projectID: CommitsMocks.mockProjectID).url)")
      XCTAssertNotNil(mockSession.lastRequest)
      XCTAssertNotNil(mockSession.lastRequest!.httpBody)

      let bodyData = mockSession.lastRequest!.httpBody!
      XCTAssertEqual(mockSession.lastRequest?.httpMethod, HTTPMethod.post.rawValue)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"])
      XCTAssertEqual(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"], "application/json")
      XCTAssertEqual(commit.id, "ed899a2f4b50b4370feeea94676502b42383c746")
      XCTAssertEqual(commit.shortId, "ed899a2f4b5")
      XCTAssertEqual(commit.title, "some commit message")

      guard let dict = try? JSONSerialization.jsonObject(with: bodyData, options: .mutableContainers) as! [String: Any] else {
        XCTFail(HTTPError.noData.localizedDescription)
        return
      }

      XCTAssertNotNil(dict["actions"])
      XCTAssertNotNil(dict["branch"])
      XCTAssertNotNil(dict["commit_message"])
      XCTAssertEqual(dict["branch"]! as! String, "master")
      XCTAssertEqual(dict["commit_message"]! as! String, "some commit message")
      XCTAssertEqual((dict["actions"]! as! [Any]).count, 5)
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }

  }

  func testGetReferences() {
    mockSession.nextData = CommitsMocks.referencesResponseData
    let references = client.commits.getReferences(projectID: CommitsMocks.mockProjectID, sha: "ed899a2f4b50b4370feeea94676502b42383c746", parameters: nil)
    let result = references
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
            XCTAssertEqual(mockSession.lastURL?.pathComponents[1...8].joined(separator: "/"),"api/v4/projects/12345/repository/commits/ed899a2f4b50b4370feeea94676502b42383c746/refs")
      XCTAssertEqual(element.count, 1)
      let references = element.first!
      XCTAssertEqual(references.count, 4)
      XCTAssertEqual(references[0].type, "branch")
      XCTAssertEqual(references[0].name, "'test'")
      XCTAssertEqual(references[1].name, "add-balsamiq-file")
      XCTAssertEqual(references[3].type, "tag")
      XCTAssertEqual(references[3].name, "v1.1.0")
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testCherryPick() {
    mockSession.nextData = CommitsMocks.cherryPickResponseData
    let projectID = 8908
    let sha = "ouqertjnsmvnjhrejk"
    let branch = "master"
    let commit = client.commits.cherryPick(projectID: projectID, sha: sha, branch: branch)

    let result = commit
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
      XCTAssertEqual(mockSession.lastURL?.pathComponents[1...8].joined(separator: "/"),"api/v4/projects/8908/repository/commits/ouqertjnsmvnjhrejk/cherry_pick")
      XCTAssertEqual(element.count, 1)
      let commit = element.first!

      XCTAssertNotNil(mockSession.lastURL)
      XCTAssertEqual(URLComponents(url: mockSession.lastURL!, resolvingAgainstBaseURL: false)!.path, "\(RxGitLabAPIClient.apiVersionURLString)\(CommitsEndpointGroup.Endpoints.cherryPick(projectID: projectID, sha: sha).url)")
      XCTAssertNotNil(mockSession.lastRequest)
      XCTAssertNotNil(mockSession.lastRequest!.httpBody)
      XCTAssertEqual(String(data: mockSession.lastRequest!.httpBody!, encoding: .utf8), "{\"branch\":\"master\"}")
      XCTAssertEqual(mockSession.lastRequest?.httpMethod, HTTPMethod.post.rawValue)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"])

      XCTAssertEqual(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"], "application/json")

      XCTAssertEqual(commit.id, "8b090c1b79a14f2bd9e8a738f717824ff53aebad")
      XCTAssertEqual(commit.shortId, "8b090c1b")

    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testGetComments() {
    mockSession.nextData = CommitsMocks.commentsData
    let comments = client.commits.getComments(projectID: CommitsMocks.mockProjectID, sha: "ed899a2f4b50b4370feeea94676502b42383c746")
    let result = comments
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
      XCTAssertEqual(mockSession.lastURL?.pathComponents[1...8].joined(separator: "/"),"api/v4/projects/12345/repository/commits/ed899a2f4b50b4370feeea94676502b42383c746/comments")
      XCTAssertEqual(element.count, 1)
      let comments = element.first!
      XCTAssertEqual(comments.count, 1)
      let comment = comments.first!
      XCTAssertEqual(comment.note, "this code is really nice")
      XCTAssertNotNil(comment.author)
      let author = comment.author!
      XCTAssertEqual(author.id, 11)
      XCTAssertEqual(author.username, "admin")
      XCTAssertEqual(author.email, "admin@local.host")
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testPostComment() {
    mockSession.nextData = CommitsMocks.commentResponseData
    let projectID = CommitsMocks.mockProjectID
    let sha = "18f3e63d05582537db6d183d9d557be09e1f90c8"
    let note = "Nice picture man!"
    let lineType = "new"
    let path = "dudeism.md"
    let comment: Comment = Comment(note: note, lineType: lineType, line: 1, path: path)

    let result = client.commits.postComment(comment: comment, projectID: projectID, sha: sha)
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
     XCTAssertEqual(mockSession.lastURL?.pathComponents[1...8].joined(separator: "/"),"api/v4/projects/12345/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/comments")
     XCTAssertEqual(mockSession.lastRequest?.httpMethod, HTTPMethod.post.rawValue)
      XCTAssertEqual(element.count, 1)
      let comment = element.first!
      XCTAssertNotNil(mockSession.lastURL)
      XCTAssertEqual(URLComponents(url: mockSession.lastURL!, resolvingAgainstBaseURL: false)!.path, "\(RxGitLabAPIClient.apiVersionURLString)\(CommitsEndpointGroup.Endpoints.comments(projectID: projectID, sha: sha).url)")
      XCTAssertNotNil(mockSession.lastRequest)
      XCTAssertNotNil(mockSession.lastRequest!.httpBody)
      XCTAssertEqual(mockSession.lastRequest?.httpMethod, HTTPMethod.post.rawValue)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"])
      XCTAssertEqual(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"], "application/json")

      XCTAssertEqual(comment.note, note)
      XCTAssertNotNil(comment.author)
      let author = comment.author!
      XCTAssertEqual(author.id, 28)
      XCTAssertEqual(author.username, "thedude")
      XCTAssertEqual(author.name, "Jeff Lebowski")
      XCTAssertEqual(comment.lineType, lineType)
      XCTAssertEqual(comment.path, path)

      let date = calendar.date(from: DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 2016, month: 1, day: 19, hour: 9, minute: 44, second: 55))!
      XCTAssertEqual(comment.createdAt, date)

    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testGetStatuses() {
    mockSession.nextData = CommitsMocks.commitStatusesData
    let statuses = client.commits.getStatuses(projectID: CommitsMocks.mockProjectID, sha: "ed899a2f4b50b4370feeea94676502b42383c746")
    let result = statuses
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
      XCTAssertEqual(mockSession.lastURL?.pathComponents[1...8].joined(separator: "/"),"api/v4/projects/12345/repository/commits/ed899a2f4b50b4370feeea94676502b42383c746/statuses")

      let date = calendar.date(from: DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 2016, month: 1, day: 19, hour: 8, minute: 40, second: 25))!

      XCTAssertEqual(element.count, 1)
      let statuses = element.first!
      XCTAssertEqual(statuses.count, 2)
      let firstStatus = statuses[0]
      XCTAssertEqual(firstStatus.status, "pending")
      XCTAssertEqual(firstStatus.createdAt, date)
      XCTAssertEqual(firstStatus.allowFailure, true)
      XCTAssertEqual(firstStatus.id, 91)
      XCTAssertEqual(firstStatus.sha, "18f3e63d05582537db6d183d9d557be09e1f90c8")
      XCTAssertNil(firstStatus.startedAt)
      XCTAssertNil(firstStatus.description)
      XCTAssertNil(firstStatus.finishedAt)
      XCTAssertNotNil(firstStatus.author)
      let author = firstStatus.author!
      XCTAssertEqual(author.id, 28)
      XCTAssertEqual(author.name, "Jeff Lebowski")
      XCTAssertEqual(author.webURL, "https://gitlab.example.com/thedude")
      XCTAssertEqual(author.avatarURL, "https://gitlab.example.com/uploads/user/avatar/28/The-Big-Lebowski-400-400.png")
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testPostStatus() {
    mockSession.nextData = CommitsMocks.buildCommitStatusResponseData
    let projectID = CommitsMocks.mockProjectID
    let sha = "18f3e63d05582537db6d183d9d557be09e1f90c8"

    let status = BuildStatus(state: BuildStatus.State.canceled.rawValue, ref: nil, name: nil, targetURL: nil, description: nil, coverage: nil)
    let result = client.commits.postStatus(status: status, projectID: projectID, sha: sha)
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
      XCTAssertEqual(mockSession.lastURL?.pathComponents[1...6].joined(separator: "/"),"api/v4/projects/12345/statuses/18f3e63d05582537db6d183d9d557be09e1f90c8")
      XCTAssertEqual(mockSession.lastRequest?.httpMethod, HTTPMethod.post.rawValue)
      XCTAssertEqual(element.count, 1)
      let status = element.first!
      XCTAssertNotNil(mockSession.lastURL)
      XCTAssertEqual(URLComponents(url: mockSession.lastURL!, resolvingAgainstBaseURL: false)!.path, "\(RxGitLabAPIClient.apiVersionURLString)\(CommitsEndpointGroup.Endpoints.statuses(projectID: CommitsMocks.mockProjectID, sha: sha).url)")
      XCTAssertNotNil(mockSession.lastRequest)
      XCTAssertNotNil(mockSession.lastRequest!.httpBody)
      XCTAssertEqual(mockSession.lastRequest?.httpMethod, HTTPMethod.post.rawValue)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields)
      XCTAssertNotNil(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"])
      XCTAssertEqual(mockSession.lastRequest!.allHTTPHeaderFields!["Content-Type"], "application/json")

      XCTAssertEqual(status.status, "success")
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

  func testGetMergeRequests() {
    mockSession.nextData = CommitsMocks.mergeRequestsData
    let statuses = client.commits.getMergeRequests(projectID: CommitsMocks.mockProjectID, sha: "ed899a2f4b50b4370feeea94676502b42383c746")
    let result = statuses
      .toBlocking()
      .materialize()

    switch result {
    case .completed(elements: let element):
      XCTAssertEqual(mockSession.lastURL?.pathComponents[1...8].joined(separator: "/"),"api/v4/projects/12345/repository/commits/ed899a2f4b50b4370feeea94676502b42383c746/merge_requests")
      XCTAssertEqual(element.count, 1)
      let mergeRequest = element.first!.first!
      let date = calendar.date(from: DateComponents(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0), year: 2018, month: 3, day: 26, hour: 17, minute: 26, second: 30))!

      XCTAssertEqual(mergeRequest.id, 45)
      XCTAssertEqual(mergeRequest.iid, 1)
      XCTAssertEqual(mergeRequest.projectID, 35)
      XCTAssertEqual(mergeRequest.title, "Add new file")
      XCTAssertEqual(mergeRequest.description, "")
      XCTAssertEqual(mergeRequest.state, "opened")
      XCTAssertEqual(mergeRequest.createdAt, date)
      XCTAssertEqual(mergeRequest.updatedAt, date)
      XCTAssertEqual(mergeRequest.targetBranch, "master")
      XCTAssertEqual(mergeRequest.sourceProjectID, 35)
      XCTAssertEqual(mergeRequest.targetProjectID, 35)
      XCTAssertEqual(mergeRequest.labels, [])
      XCTAssertEqual(mergeRequest.workInProgress, false)
      XCTAssertNil(mergeRequest.milestone)
      XCTAssertEqual(mergeRequest.mergeWhenPipelineSucceeds, false)
      XCTAssertEqual(mergeRequest.sha, "af5b13261899fb2c0db30abdd0af8b07cb44fdc5")
      XCTAssertEqual(mergeRequest.mergeStatus, "can_be_merged")
      XCTAssertNil(mergeRequest.mergeCommitSHA)
      XCTAssertEqual(mergeRequest.userNotesCount, 0)
      XCTAssertNil(mergeRequest.discussionLocked)
      XCTAssertNil(mergeRequest.shouldRemoveSourceBranch)
      XCTAssertEqual(mergeRequest.forceRemoveSourceBranch, false)
      XCTAssertEqual(mergeRequest.webURL, "http://https://gitlab.example.com/root/test-project/merge_requests/1")
      XCTAssertNotNil(mergeRequest.timeStats)
      let timeStats = mergeRequest.timeStats!
      XCTAssertEqual(timeStats.timeEstimate, 0)
      XCTAssertEqual(timeStats.totalTimeSpent, 0)
      XCTAssertEqual(timeStats.humanTimeEstimate, 1)
      XCTAssertEqual(timeStats.humanTotalTimeSpent, 2)
    case .failed(elements: _, error: let error):
      XCTFail((error as? HTTPError)?.errorDescription ?? error.localizedDescription)
    }
  }

}
