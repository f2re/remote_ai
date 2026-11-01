import Foundation

enum StableHash {
    static func fnv1a64(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }
}

enum Identifier {
    static func sanitize(_ value: String, fallback: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let scalars = value.unicodeScalars.filter { allowed.contains($0) }
        let result = String(String.UnicodeScalarView(scalars))
        return result.isEmpty ? fallback : result
    }
}

enum LocalPath {
    static func expandTilde(_ value: String) -> String {
        (value as NSString).expandingTildeInPath
    }
}

enum Shell {
    static func quote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}

enum RemotePath {
    static func shellExpression(_ path: String) -> String {
        if path.hasPrefix("~/") {
            return "\"$HOME\"/" + Shell.quote(String(path.dropFirst(2)))
        }
        if path.hasPrefix("/") {
            return Shell.quote(path)
        }
        return "\"$HOME\"/" + Shell.quote(path)
    }
}

enum AppleScriptEscaping {
    static func stringLiteral(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
