//
//  QuestionsLoadingTests.swift
//  dinIslamTests
//
//  Фиксируют ТЕКУЩЕЕ поведение загрузки вопросов (GitHub → кэш → встроенные)
//  перед рефакторингом Этапа 3. Сеть подменяется через URLProtocol,
//  кэш пишется во временную папку — реальный кэш приложения не трогается.
//

import XCTest
@testable import dinIslam

final class QuestionsLoadingTests: XCTestCase {

    private var cacheDirectory: URL!

    override func setUp() {
        super.setUp()
        cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuestionsLoadingTests-\(UUID().uuidString)")
        StubURLProtocol.reset()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        StubURLProtocol.reset()
        cacheDirectory = nil
        super.tearDown()
    }

    // MARK: - GitHub

    func testNoCache_loadsFromGitHub_andSavesToCache() async {
        StubURLProtocol.respond(status: 200, etag: "\"v1\"", body: Self.remoteJSON(ids: ["q1", "q2"]))
        let (service, cache) = makeService()

        let questions = await service.fetchQuestions(for: .russian, manageLoadingState: false)

        XCTAssertEqual(questions.map(\.id), ["q1", "q2"])
        XCTAssertEqual(StubURLProtocol.requests.count, 1)
        XCTAssertEqual(StubURLProtocol.requests.first?.url?.lastPathComponent, "questions.json")
        let cached = cache.getCachedDataWithMetadata([Question].self, for: "questions_ru")
        XCTAssertEqual(cached?.data.map(\.id), ["q1", "q2"])
        XCTAssertEqual(cached?.etag, "\"v1\"")
    }

    func testEnglish_requestsEnglishFile() async {
        StubURLProtocol.respond(status: 200, etag: nil, body: Self.remoteJSON(ids: ["e1"]))
        let (service, _) = makeService()

        let questions = await service.fetchQuestions(for: .english, manageLoadingState: false)

        XCTAssertEqual(questions.map(\.id), ["e1"])
        XCTAssertEqual(StubURLProtocol.requests.first?.url?.lastPathComponent, "questions_en.json")
    }

    // MARK: - Кэш

    func testFreshCache_isUsedWithoutNetworkRequest() async {
        let (service, cache) = makeService()
        cache.cacheData(Self.questions(ids: ["c1", "c2"]), for: "questions_ru", etag: "\"v1\"")

        let questions = await service.fetchQuestions(for: .russian, manageLoadingState: false)

        XCTAssertEqual(questions.map(\.id), ["c1", "c2"])
        XCTAssertTrue(StubURLProtocol.requests.isEmpty, "Свежий кэш не должен вызывать запрос в сеть")
    }

    func testExpiredCache_304_returnsCachedQuestions_andSendsETag() async {
        StubURLProtocol.respond(status: 304, etag: "\"v1\"", body: Data())
        let (service, cache) = makeService(ttl: -1) // кэш сразу считается устаревшим
        cache.cacheData(Self.questions(ids: ["c1", "c2"]), for: "questions_ru", etag: "\"v1\"")

        let questions = await service.fetchQuestions(for: .russian, manageLoadingState: false)

        XCTAssertEqual(questions.map(\.id), ["c1", "c2"])
        XCTAssertEqual(StubURLProtocol.requests.first?.value(forHTTPHeaderField: "If-None-Match"), "\"v1\"")
    }

    func testExpiredCache_200_replacesCache() async {
        StubURLProtocol.respond(status: 200, etag: "\"v2\"", body: Self.remoteJSON(ids: ["n1", "n2", "n3"]))
        let (service, cache) = makeService(ttl: -1)
        cache.cacheData(Self.questions(ids: ["c1"]), for: "questions_ru", etag: "\"v1\"")

        let questions = await service.fetchQuestions(for: .russian, manageLoadingState: false)

        XCTAssertEqual(questions.map(\.id), ["n1", "n2", "n3"])
        let cached = cache.getCachedDataWithMetadata([Question].self, for: "questions_ru")
        XCTAssertEqual(cached?.data.map(\.id), ["n1", "n2", "n3"])
        XCTAssertEqual(cached?.etag, "\"v2\"")
    }

    func testNetworkError_usesExpiredCache() async {
        StubURLProtocol.fail(with: URLError(.notConnectedToInternet))
        let (service, cache) = makeService(ttl: -1)
        cache.cacheData(Self.questions(ids: ["c1", "c2"]), for: "questions_ru", etag: "\"v1\"")

        let questions = await service.fetchQuestions(for: .russian, manageLoadingState: false)

        XCTAssertEqual(questions.map(\.id), ["c1", "c2"])
    }

    // MARK: - Ошибки в данных

    /// ТЕКУЩЕЕ поведение: один неправильный вопрос отбрасывает весь файл с GitHub.
    /// После Этапа 3 плохой вопрос должен пропускаться, а остальные — загружаться.
    func testOneInvalidQuestion_currentlyRejectsWholeFile() async {
        var items = Self.remoteItems(ids: ["n1", "n2"])
        items.append(["id": "bad", "q": "Вопрос с одним ответом", "a": ["Единственный"], "c": 0])
        StubURLProtocol.respond(status: 200, etag: "\"v2\"", body: Self.json(items))
        let (service, cache) = makeService(ttl: -1)
        cache.cacheData(Self.questions(ids: ["c1"]), for: "questions_ru", etag: "\"v1\"")

        let questions = await service.fetchQuestions(for: .russian, manageLoadingState: false)

        XCTAssertEqual(questions.map(\.id), ["c1"], "Сейчас весь файл отбрасывается и берётся старый кэш")
    }

    // MARK: - Встроенные вопросы

    /// Нет сети и нет кэша → должны загрузиться вопросы, встроенные в приложение.
    /// ИЗВЕСТНАЯ ОШИБКА: встроенные файлы в коротком формате (q/a/c), а код читает
    /// их как полный формат (text/answers) и получает пустой список.
    /// Когда ошибку исправят, XCTExpectFailure сообщит об этом — его нужно будет убрать.
    func testNoNetwork_noCache_fallsBackToBundledQuestions() async {
        StubURLProtocol.fail(with: URLError(.notConnectedToInternet))
        let (service, _) = makeService()

        let questions = await service.fetchQuestions(for: .russian, manageLoadingState: false)

        XCTExpectFailure("Известная ошибка: встроенные вопросы не декодируются (формат q/a/c)")
        XCTAssertFalse(questions.isEmpty, "Встроенные вопросы должны загружаться без сети")
    }

    func testBundledQuestionFiles_existAndAreNotEmpty() throws {
        for name in ["questions", "questions_en"] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "json"), "\(name).json нет в приложении")
            let items = try JSONDecoder().decode([RemoteQuestion].self, from: Data(contentsOf: url))
            XCTAssertFalse(items.isEmpty, "\(name).json пустой")
        }
    }

    // MARK: - Helpers

    private func makeService(ttl: TimeInterval = 6 * 60 * 60) -> (EnhancedRemoteQuestionsService, CacheManager) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [StubURLProtocol.self]
        sessionConfig.urlCache = nil
        let network = NetworkManager(
            configuration: NetworkConfiguration(timeout: 5, maxRetries: 0, retryDelay: 0, maxRetryDelay: 0),
            session: URLSession(configuration: sessionConfig),
            monitorsNetwork: false
        )
        let cacheConfig = CacheConfiguration(ttl: ttl, maxCacheSize: 10 * 1024 * 1024, compressionEnabled: false)
        let cache = CacheManager(configuration: cacheConfig, cacheDirectory: cacheDirectory)
        let service = EnhancedRemoteQuestionsService(networkManager: network, cacheManager: cache, configuration: cacheConfig)
        return (service, cache)
    }

    private static func remoteItems(ids: [String]) -> [[String: Any]] {
        ids.map { ["id": $0, "q": "Вопрос \($0)", "a": ["Ответ 1", "Ответ 2", "Ответ 3"], "c": 1] }
    }

    private static func remoteJSON(ids: [String]) -> Data {
        json(remoteItems(ids: ids))
    }

    private static func json(_ items: [[String: Any]]) -> Data {
        // swiftlint:disable:next force_try
        try! JSONSerialization.data(withJSONObject: items)
    }

    private static func questions(ids: [String]) -> [Question] {
        ids.map {
            Question(
                id: $0,
                text: "Кэш \($0)",
                answers: [Answer(id: "a1", text: "Да"), Answer(id: "a2", text: "Нет")],
                correctIndex: 0,
                category: "test",
                difficulty: .easy
            )
        }
    }
}

// MARK: - Stub URLProtocol

private final class StubURLProtocol: URLProtocol {
    private enum Stub {
        case response(status: Int, etag: String?, body: Data)
        case failure(Error)
    }

    private static let lock = NSLock()
    private static var stub: Stub?
    private static var _requests: [URLRequest] = []

    static var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return _requests
    }

    static func respond(status: Int, etag: String?, body: Data) {
        lock.lock(); defer { lock.unlock() }
        stub = .response(status: status, etag: etag, body: body)
    }

    static func fail(with error: Error) {
        lock.lock(); defer { lock.unlock() }
        stub = .failure(error)
    }

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        stub = nil
        _requests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self._requests.append(request)
        let current = Self.stub
        Self.lock.unlock()

        switch current {
        case .response(let status, let etag, let body):
            var headers = ["Content-Type": "application/json"]
            if let etag { headers["ETag"] = etag }
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
        }
    }

    override func stopLoading() {}
}
