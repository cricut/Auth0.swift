import Foundation
import Combine
import Quick
import Nimble
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif

@testable import Auth0

private let Url = URL(string: "https://samples.auth0.com")!
private let Timeout: DispatchTimeInterval = .seconds(2)

class RequestSpec: QuickSpec {
    override func spec() {

        beforeEach {
            stub(condition: isHost(Url.host!)) { _
                in HTTPStubsResponse.init(error: NSError(domain: "com.auth0", code: -99999, userInfo: nil))
            }.name = "YOU SHALL NOT PASS!"
        }

        describe("create and update request") {

            context("parameters") {

                it("should create a request with parameters") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, parameters: ["foo": "bar"], logger: nil, telemetry: Telemetry())
                    expect(request.parameters["foo"] as? String) == "bar"
                }

                it("should create a new request with extra parameters") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, logger: nil, telemetry: Telemetry()).parameters(["foo": "bar"])
                    expect(request.parameters["foo"] as? String) == "bar"
                }

                it("should merge extra parameters with existing parameters") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, parameters: ["foo": "bar"], logger: nil, telemetry: Telemetry()).parameters(["baz": "qux"])
                    expect(request.parameters["foo"] as? String) == "bar"
                    expect(request.parameters["baz"] as? String) == "qux"
                }

                it("should overwrite existing parameters with extra parameters") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, parameters: ["foo": "bar"], logger: nil, telemetry: Telemetry()).parameters(["foo": "baz"])
                    expect(request.parameters["foo"] as? String) == "baz"
                }

                it("should create a new request and not mutate an existing request") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, parameters: ["foo": "bar"], logger: nil, telemetry: Telemetry())
                    expect(request.parameters(["foo": "baz"]).parameters["foo"] as? String) == "baz"
                    expect(request.parameters["foo"] as? String) == "bar"
                }

            }

            context("headers") {

                it("should create a request with headers") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry())
                    expect(request.headers["foo"]) == "bar"
                }

                it("should create a new request with extra headers") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, logger: nil, telemetry: Telemetry()).headers(["foo": "bar"])
                    expect(request.headers["foo"]) == "bar"
                }

                it("should merge extra headers with existing headers") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry()).headers(["baz": "qux"])
                    expect(request.headers["foo"]) == "bar"
                    expect(request.headers["baz"]) == "qux"
                }

                it("should overwrite existing headers with extra headers") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry()).headers(["foo": "baz"])
                    expect(request.headers["foo"]) == "baz"
                }

                it("should create a new request and not mutate an existing request") {
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, headers: ["foo": "bar"], logger: nil, telemetry: Telemetry())
                    expect(request.headers(["foo": "baz"]).headers["foo"]) == "baz"
                    expect(request.headers["foo"]) == "bar"
                }

            }

        }

        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
            describe("combine") {
                var cancellables: Set<AnyCancellable> = []

                afterEach {
                    cancellables.removeAll()
                }

                it("should emit only one value") {
                    stub(condition: isHost(Url.host!)) { _ in
                        return HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
                    }
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, logger: nil, telemetry: Telemetry())
                    waitUntil(timeout: Timeout) { done in
                        request
                            .publisher()
                            .assertNoFailure()
                            .count()
                            .sink(receiveValue: { count in
                                expect(count).to(equal(1))
                                done()
                            })
                            .store(in: &cancellables)
                    }
                }

                it("should complete with the response") {
                    stub(condition: isHost(Url.host!)) { _ in
                        return HTTPStubsResponse(jsonObject: ["foo": "bar"], statusCode: 200, headers: nil)
                    }
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, logger: nil, telemetry: Telemetry())
                    waitUntil(timeout: Timeout) { done in
                        request
                            .publisher()
                            .sink(receiveCompletion: { completion in
                                guard case .finished = completion else { return }
                                done()
                            }, receiveValue: { response in
                                expect(response).toNot(beEmpty())
                            })
                            .store(in: &cancellables)
                    }
                }

                it("should complete with an error") {
                    stub(condition: isHost(Url.host!)) { _ in
                        return authFailure()
                    }
                    let request = Request(session: URLSession.shared, url: Url, method: "GET", handle: plainJson, logger: nil, telemetry: Telemetry())
                    waitUntil(timeout: Timeout) { done in
                        request
                            .publisher()
                            .ignoreOutput()
                            .sink(receiveCompletion: { completion in
                                guard case .failure = completion else { return }
                                done()
                            }, receiveValue: { _ in })
                            .store(in: &cancellables)
                    }
                }

            }
        }

    }
}
