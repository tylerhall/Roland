//
//  Template.swift
//  roland
//

import Foundation

class Template {

    static let PHP = """
<?PHP
include('functions.inc.php');
$json_str = base64_decode('ROLAND_BASE64');
$ROLAND_CONTEXT = json_decode($json_str, JSON_OBJECT_AS_ARRAY);
if(is_array($ROLAND_CONTEXT)) {
    foreach($ROLAND_CONTEXT as $k => $v) {
        extract($v, EXTR_PREFIX_ALL, $k);
    }
}
?>
"""

    var website: Website!
    var templateName: String
    var templateFileURL: URL

    init(templateFileURL: URL, website: Website) {
        self.website = website
        self.templateFileURL = templateFileURL
        let noExtension = templateFileURL.deletingPathExtension()
        self.templateName = noExtension.lastPathComponent
    }

    init(templateName: String, website: Website) {
        self.website = website
        self.templateName = templateName
        self.templateFileURL = website.templateDirURL.appendingPathComponent("\(templateName).php")
        
        if !templateFileURL.isAccessibleFile {
            print("Error: Template is not accessible \(templateFileURL.path)")
            exit(EXIT_FAILURE)
        }
    }

    func render(context: [String: Any?]? = nil) -> String? {
        do {
            let templateContents = try String(contentsOf: templateFileURL)
            let script = Template.PHP + templateContents
            let json = jsonContext(context: context)
            let output = executePHP(script: script, context: json)
            return output
        } catch {
            return nil
        }
    }

    func jsonContext(context: [String: Any?]? = nil) -> String? {
        guard let context = context else { return nil }

        do {
            let data = try JSONSerialization.data(withJSONObject: context, options: .init())
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    func executePHP(script: String, context: String? = nil) -> String? {
        let task = Process()

        let stdin = Pipe()
        let stdout = Pipe()

        // TODO: We need to auto-detect where php is in the user's $PATH,
        // or maybe allow them to explicitly define the location themselves.
        task.launchPath = "/usr/bin/php"
        task.currentDirectoryURL = website.templateDirURL
        task.standardInput = stdin
        task.standardOutput = stdout
        task.launch()
        
        let base64Str = context?.data(using: .utf8)?.base64EncodedString()

        let contextualizedScript = script.replacingOccurrences(of: "ROLAND_BASE64", with: base64Str ?? "")
        let scriptData = contextualizedScript.data(using: .utf8)

        let writeHandle = stdin.fileHandleForWriting
        writeHandle.write(scriptData ?? Data())
        writeHandle.closeFile()

        let readHandle = stdout.fileHandleForReading
        let data = readHandle.readDataToEndOfFile()
        readHandle.closeFile()

        return String(data: data, encoding: .utf8)
    }
}
