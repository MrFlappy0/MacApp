import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// Utilitaires pour la gestion des fichiers
class FileUtilities {
    static let shared = FileUtilities()
    
    private init() {}
    
    /// Obtient le type UTI pour une extension de fichier
    func getUTType(for fileExtension: String) -> UTType? {
        switch fileExtension.lowercased() {
        case "txt": return .plainText
        case "md": return .markdown
        case "json": return .json
        case "csv": return .commaSeparatedText
        case "pdf": return .pdf
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "gif": return .gif
        case "heic": return .heic
        case "mp3": return .mp3
        case "wav": return .wav
        case "aac": return .aacAudio
        case "mp4": return .mpeg4Movie
        case "mov": return .quickTimeMovie
        case "avi": return UTType(filenameExtension: "avi")
        case "zip": return .zip
        case "tar": return UTType(filenameExtension: "tar")
        case "gz": return UTType(filenameExtension: "gz")
        case "py": return UTType(filenameExtension: "py")
        case "swift": return UTType(filenameExtension: "swift")
        case "html": return UTType(filenameExtension: "html")
        case "css": return UTType(filenameExtension: "css")
        case "js": return UTType(filenameExtension: "js")
        default: return nil
        }
    }
    
    /// Obtient l'icône pour un type de fichier
    func getIcon(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "txt", "md", "csv", "json", "xml", "html", "css", "js": return "doc.text"
        case "pdf": return "doc.text.magnifyingglass"
        case "jpg", "jpeg", "png", "gif", "heic", "webp": return "photo"
        case "mp3", "wav", "aac", "flac", "ogg": return "waveform"
        case "mp4", "mov", "avi", "mkv", "webm": return "video"
        case "zip", "tar", "gz", "rar", "7z": return "folder"
        case "py": return "{}"
        case "swift": return "swift"
        case "xcodeproj": return "folder"
        case "plist": return "slider.horizontal.3"
        default: return "doc"
        }
    }
    
    /// Obtient la couleur pour un type de fichier
    func getColor(for fileExtension: String) -> Color {
        switch fileExtension.lowercased() {
        case "txt", "md": return .blue
        case "json", "xml": return .yellow
        case "csv": return .green
        case "pdf": return .red
        case "jpg", "jpeg", "png", "gif", "heic", "webp": return .purple
        case "mp3", "wav", "aac", "flac", "ogg": return .orange
        case "mp4", "mov", "avi", "mkv", "webm": return .pink
        case "zip", "tar", "gz", "rar", "7z": return .brown
        case "py": return .green
        case "swift": return .orange
        case "html", "css", "js": return .blue
        default: return .gray
        }
    }
    
    /// Obtient la catégorie pour un type de fichier
    func getCategory(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "txt", "md", "csv", "json", "xml": return "Texte"
        case "pdf": return "Document"
        case "jpg", "jpeg", "png", "gif", "heic", "webp": return "Image"
        case "mp3", "wav", "aac", "flac", "ogg": return "Audio"
        case "mp4", "mov", "avi", "mkv", "webm": return "Vidéo"
        case "zip", "tar", "gz", "rar", "7z": return "Archive"
        case "py", "swift", "java", "c", "cpp", "h", "hpp": return "Code"
        case "html", "css", "js": return "Web"
        default: return "Autre"
        }
    }
    
    /// Vérifie si un fichier est un fichier texte
    func isTextFile(_ fileExtension: String) -> Bool {
        let textExtensions = ["txt", "md", "json", "csv", "xml", "html", "css", "js", "py", "swift", "java", "c", "cpp", "h", "hpp", "sh", "bash"]
        return textExtensions.contains(fileExtension.lowercased())
    }
    
    /// Lit le contenu d'un fichier texte
    func readTextFile(_ url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    /// Obtient un aperçu d'un fichier
    func getPreview(for url: URL, maxLength: Int = 200) -> String? {
        guard isTextFile(url.pathExtension) else { return nil }
        
        guard let content = readTextFile(url) else { return nil }
        
        if content.count <= maxLength {
            return content
        } else {
            return String(content.prefix(maxLength)) + "..."
        }
    }
    
    /// Obtient la taille d'un fichier
    func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Formate la taille d'un fichier
    func formatFileSize(_ size: Int64) -> String {
        let bytes = Double(size)
        
        if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.2f Go", bytes / (1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.2f Mo", bytes / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.2f Ko", bytes / 1024)
        } else {
            return "\(size) o"
        }
    }
    
    /// Copie un fichier
    func copyFile(from sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            return false
        }
    }
    
    /// Déplace un fichier
    func moveFile(from sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            return false
        }
    }
    
    /// Supprime un fichier
    func deleteFile(_ url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
    
    /// Vérifie si un fichier existe
    func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Crée un répertoire
    func createDirectory(_ url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
    }
    
    /// Liste les fichiers dans un répertoire
    func listFiles(in directoryURL: URL) -> [URL]? {
        do {
            return try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        } catch {
            return nil
        }
    }
    
    /// Obtient l'extension d'un fichier
    func getFileExtension(_ url: URL) -> String {
        url.pathExtension
    }
    
    /// Obtient le nom du fichier sans extension
    func getFileNameWithoutExtension(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
    
    /// Obtient le nom du fichier
    func getFileName(_ url: URL) -> String {
        url.lastPathComponent
    }
    
    /// Obtient le chemin parent
    func getParentDirectory(_ url: URL) -> URL {
        url.deletingLastPathComponent()
    }
}

/// Extension pour URL pour faciliter la manipulation des fichiers
extension URL {
    var fileSize: Int64 {
        FileUtilities.shared.getFileSize(self)
    }
    
    var fileExtension: String {
        FileUtilities.shared.getFileExtension(self)
    }
    
    var fileName: String {
        FileUtilities.shared.getFileName(self)
    }
    
    var fileNameWithoutExtension: String {
        FileUtilities.shared.getFileNameWithoutExtension(self)
    }
    
    var parentDirectory: URL {
        FileUtilities.shared.getParentDirectory(self)
    }
    
    var isTextFile: Bool {
        FileUtilities.shared.isTextFile(pathExtension)
    }
    
    var preview: String? {
        FileUtilities.shared.getPreview(for: self)
    }
    
    var formattedSize: String {
        FileUtilities.shared.formatFileSize(fileSize)
    }
    
    var iconName: String {
        FileUtilities.shared.getIcon(for: pathExtension)
    }
    
    var color: Color {
        FileUtilities.shared.getColor(for: pathExtension)
    }
    
    var category: String {
        FileUtilities.shared.getCategory(for: pathExtension)
    }
}

/// Gestionnaire de fichiers pour le chat
class ChatFileManager {
    static let shared = ChatFileManager()
    
    private let fileUtilities = FileUtilities.shared
    private let chatFilesDirectory: URL
    
    private init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        chatFilesDirectory = documentsURL.appendingPathComponent("MLXChatApp/Files", isDirectory: true)
        
        fileUtilities.createDirectory(chatFilesDirectory)
    }
    
    /// Sauvegarde un fichier joint
    func saveAttachment(_ url: URL, for sessionId: UUID) -> URL? {
        let sessionDirectory = chatFilesDirectory.appendingPathComponent(sessionId.uuidString, isDirectory: true)
        fileUtilities.createDirectory(sessionDirectory)
        
        let destinationURL = sessionDirectory.appendingPathComponent(url.fileName)
        
        if fileUtilities.copyFile(from: url, to: destinationURL) {
            return destinationURL
        }
        
        return nil
    }
    
    /// Supprime les fichiers d'une session
    func deleteSessionFiles(_ sessionId: UUID) {
        let sessionDirectory = chatFilesDirectory.appendingPathComponent(sessionId.uuidString, isDirectory: true)
        
        if let files = fileUtilities.listFiles(in: sessionDirectory) {
            for file in files {
                fileUtilities.deleteFile(file)
            }
        }
        
        fileUtilities.deleteFile(sessionDirectory)
    }
    
    /// Liste les fichiers d'une session
    func listSessionFiles(_ sessionId: UUID) -> [URL]? {
        let sessionDirectory = chatFilesDirectory.appendingPathComponent(sessionId.uuidString, isDirectory: true)
        return fileUtilities.listFiles(in: sessionDirectory)
    }
    
    /// Obtient l'URL pour un fichier de session
    func getURLForSessionFile(_ sessionId: UUID, fileName: String) -> URL {
        let sessionDirectory = chatFilesDirectory.appendingPathComponent(sessionId.uuidString, isDirectory: true)
        return sessionDirectory.appendingPathComponent(fileName)
    }
}
