<h1>
    <img src="https://raw.githubusercontent.com/aplr/Henry/main/Logo.png?token=AAIAWBDNQRUM6JJJWSYHN43ASPZJS" height="23" />
    Henry
</h1>

![Build](https://github.com/aplr/Henry/workflows/Build/badge.svg?branch=main)
![Documentation](https://github.com/aplr/Henry/workflows/Documentation/badge.svg)

Henry is an easy-to-use, object-based queue with support for iOS, tvOS and macOS, written purely in Swift. Push and pop operations are both in O(1). All writes are synchronous - this means data will be written to the disk before an operation returns. Furthermore, all operations are thread-safe and synchronized using a read-write lock. This allows for synchronized, concurrent access to read-operations while performing writes in serial.

## About Henry

Henry was originally conceived as a simple object queue that allows to persist unsent messages locally in an efficient and simple way which outlasts app crashes and restarts. For its storage layer, Henry makes use of Pinterest's excellent [PINCache](https://github.com/pinterest/PINCache), which is a key/value store designed for persisting temporary objects on the disk. Beyond that, the [Deque](https://swift.org/blog/swift-collections/#deque) data structure from Apple's open source [swift-collections](https://github.com/apple/swift-collections) library is used in the internal realization of the queue.

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

As a bare minimum, you have to specify the name of the Henry which determines the queue file name, as well as the directory where the queue file is stored.

```swift
import Henry

let url = URL(fileURLWithPath: "/path/to/your/app", isDirectory: true)

let Henry = Henry<String>(name: "messages", url: url)

Henry.push("Hello")
Henry.push("World")

print(Henry.count)   // 2

print(Henry.pop())   // "Hello"
print(Henry.pop())   // "World"

print(Henry.isEmpty) // true
```

### Going LIFO

Henry uses a FIFO queue internally per default. If you want to change that behaviour to LIFO, pass a customized `HenryConfiguration` object with the strategy adjusted like below.

```swift
let url = URL(fileURLWithPath: "/path/to/your/app", isDirectory: true)

let configuration = HenryConfiguration(strategy: .lifo)

let Henry = Henry<String>(
    name: "messages",
    url: url,
    configuration: configuration
)

// ...
```

## Documentation

Documentation is available [here](https://Henry.aplr.io) and provides a comprehensive documentation of the library's public interface. Expect usage examples and guides to be added shortly.

## License

Henry is licensed under the [MIT License](https://github.com/aplr/Henry/blob/main/LICENSE).
