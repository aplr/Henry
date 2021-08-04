<h1>
    <img src="https://raw.githubusercontent.com/aplr/Henry/main/Logo.png?token=AAIAWBDNQRUM6JJJWSYHN43ASPZJS" height="23" />
    Henry
</h1>

![Build](https://github.com/aplr/Henry/workflows/Build/badge.svg?branch=main)
![Documentation](https://github.com/aplr/Henry/workflows/Documentation/badge.svg)

Henry is an easy-to-use, declarative and persistent job queue with support for iOS, tvOS and macOS, written purely in Swift. It is built upon Foundation's [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue) and supports serial, concurrent as well as blocking queues. For persisting the queue's internal state, Henry uses [Pillarbox](https://github.com/aplr/Pillarbox), which is an object-based queue working directly on the filesystem.


## About Henry

Henry was originally conceived as a task queue that allows to persist unsent chat messages locally in an efficient and simple way which outlasts app crashes and restarts. In its persistence layer, Henry makes use of [Pillarbox](https://github.com/aplr/Pillarbox), which is an object-based key/value store also providing queue operations, designed for persisting temporary objects on the disk.


## Installation

Henry is available via the [Swift Package Manager](https://swift.org/package-manager/) which is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system and automates the process of downloading, compiling, and linking dependencies.

Once you have your Swift package set up, adding Henry as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```swift
dependencies: [
    .package(
        url: "https://github.com/aplr/Henry.git",
        .upToNextMajor(from: "1.0.0")
    )
]
```


## Usage

Let's say you want to send chat messages, which is usually an error-prone task due to bad network conditions and other factors. Furthermore, you might want to send them in a strict order and cancel sending subsequent messages if one of them fails. This is exactly what you can use Henry for.

We start with a very simple message object we want to send. As jobs and their data is persisted, we have to conform to the `Codable` protocol.

```swift
struct Message: Codable {
    let id: UUID
    let sender: String
    let text: String
}
```

Next, we define a `SendMessageJob` which conforms to the `Job` protocol. It encapsulates our message to send and allows to define metadata like the maximum retries in case of failures and the job timeout. When the job is processed by the queue, the `handle` method is invoked, which is the place to implement your processing code. If the job succeeds, the `jobDidSucceed` method will be called, `jobDidFail(reason:)` otherwise.

```swift
import Henry

struct SendMessageJob: Job {

    // The message to send
    let message: Message

    // The queue will retry the job three
    // times on failure.
    var maxTries: Int {
        3
    }

    // The job will be cancelled if it runs
    // longer than this number of seconds.
    var timeout: Int {
        16
    }

    func handle(completion: (Henry.Result) -> Void) -> JobCancellable {
        let request = AF.request("https://httpbin.org/post", method: .post, parameters: message)

        // When the request completes, be sure to call the completion
        // handler with either a success or failure result
        request.validate().response { response in
            switch response.result {
            case .success: completion(.success)
            case let .failure(error): completion(.failure(error))
            }
        }

        // Provide a cancel function which allows cancelling the asynchronous operation.
        return { request.cancel() }
    }

    func jobDidSucceed() {
        MessageService.shared.markAsSent(message)
    }

    func jobDidFail(reason: Henry.FailReason) -> Henry.FailAction {
        MessageService.shared.markAsFailed(message)
    }
}
```

In order to deserialize persisted jobs, we have to register our newly created `SendMessageJob` on the queue. Then, you can continue processing the persisted jobs of your queue by calling it's `run` function. Your AppDelegate's `application(_:didFinishLaunchingWithOptions:)` is a good place to put this.

```swift
import Henry

class AppDelegate: UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Queue.register(job: SendMessageJob.self)

        // Crea
        let connection = Queue.Connection("io.aplr.henry.queue.demo-1", mode: .blocking)

        Queue(connection).run()

        return true
    }
}
```

Finally, we can dispatch our `SendMessageJob` to our queue. Just create a queue connection and use it to dispatch a job.

```swift
import Henry

let connection = Queue.Connection("io.aplr.henry.queue.demo-1", mode: .blocking)

let queue = Queue(connection)

let message = Message(id: UUID(), sender: "John Doe", text: "Hello World!")

let job = SendMessageJob(message: message)

let queuedJob = queue.dispatch(job)
```


## Documentation

Documentation is available [here](https://henry.aplr.io) and provides a comprehensive documentation of the library's public interface. Expect usage examples and guides to be added shortly.


## License

Henry is licensed under the [MIT License](https://github.com/aplr/Henry/blob/main/LICENSE).
