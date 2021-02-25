'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_languageserver_1 = require("vscode-languageserver");
const vscode_uri_1 = require("vscode-uri");
const path = require("path");
const luacheck = require("./luacheck");
const LuaVM = require('./lua.vm');
let L = new LuaVM.Lua.State();
let checker = new luacheck.luacheck(L);
// hold the useLuacheck setting
let useLuacheck;
let maxNumberOfReports;
let connection = vscode_languageserver_1.createConnection(new vscode_languageserver_1.IPCMessageReader(process), new vscode_languageserver_1.IPCMessageWriter(process));
let documents = new vscode_languageserver_1.TextDocuments();
documents.listen(connection);
// After the server has started the client sends an initialize request. The server receives
// in the passed params the rootPath of the workspace plus the client capabilities. 
let workspaceRoot;
connection.onInitialize((params) => {
    workspaceRoot = params.rootPath;
    return {
        capabilities: {
            // Tell the client that the server works in FULL text document sync mode
            textDocumentSync: documents.syncKind
        }
    };
});
// The settings have changed. Is send on server activation
// as well.
connection.onDidChangeConfiguration((change) => {
    let settings = change.settings;
    useLuacheck = settings.luacheck.useLuacheck != null ? settings.luacheck.useLuacheck : false;
    maxNumberOfReports = settings.luacheck.maxNumberOfReports || 100;
    // Revalidate any open text documents
    documents.all().forEach(validateTextDocument);
});
connection.onDidChangeWatchedFiles((handler) => {
    documents.all().forEach(validateTextDocument);
});
documents.onDidChangeContent((change) => {
    validateTextDocument(change.document);
});
documents.onDidOpen((e) => {
    validateTextDocument(e.document);
});
documents.onDidClose((e) => {
    connection.sendDiagnostics({ uri: e.document.uri, diagnostics: [] });
});
function validateTextDocument(textDocument) {
    if (useLuacheck) {
        fullcheck_by_luacheck(textDocument.getText(), textDocument.uri);
    }
    else {
        syntax_error_check(textDocument.getText(), textDocument.uri);
    }
}
function syntax_error_check(text, uri) {
    const message_parse_reg = /..+:([0-9]+): (.+) near.*[<'](.*)['>]/;
    let fspath = vscode_uri_1.default.parse(uri).fsPath;
    let diagnostics = [];
    let lineoffset = 0;
    if (text.startsWith('#')) {
        lineoffset = 1;
        text = text.substring(text.indexOf("\n") + 1);
    }
    try {
        let syntax = L.load(text, path.basename(fspath));
        syntax.free();
    }
    catch (e) {
        const match = message_parse_reg.exec(e.message);
        const error = {
            line: parseInt(match[1]),
            kind: match[2],
            near: match[3],
        };
        let lines = text.split(/\r?\n/g);
        let errorLine = lines[error.line - 1];
        let errorLineNum = lineoffset + error.line - 1;
        let errorStart = { line: errorLineNum, character: 0 };
        let errorEnd = { line: errorLineNum, character: errorLine.length };
        if (error.near != "eof") {
            let errorColstart = errorLine.indexOf(error.near);
            if (errorColstart >= 0) {
                errorStart = { line: errorLineNum, character: errorColstart };
                errorEnd = { line: errorLineNum, character: errorColstart + error.near.length };
            }
        }
        diagnostics.push({
            severity: 1 /* Error */,
            range: {
                start: errorStart,
                end: errorEnd
            },
            source: "luacheck",
            message: e.message
        });
    }
    // Send the computed diagnostics to VS Code.
    connection.sendDiagnostics({ uri: uri, diagnostics });
}
function fullcheck_by_luacheck(text, uri) {
    let fspath = vscode_uri_1.default.parse(uri).fsPath;
    var document_full_path = path.resolve(fspath);
    let diagnostics = [];
    let lineoffset = 0;
    if (text.startsWith('#')) {
        lineoffset = 1;
        text = text.substring(text.indexOf("\n") + 1);
    }
    let reports = checker.check(document_full_path, text, maxNumberOfReports);
    for (var report of reports) {
        let errorLineNum = lineoffset + report.line - 1;
        let errorStart = { line: errorLineNum, character: report.column - 1 };
        let errorEnd = { line: errorLineNum, character: report.end_column };
        let level = 2 /* Warning */;
        if (report.msg) {
            level = 1 /* Error */;
        }
        diagnostics.push({
            severity: level,
            range: {
                start: errorStart,
                end: errorEnd
            },
            source: "luacheck",
            message: report.message
        });
    }
    // Send the computed diagnostics to VS Code.
    connection.sendDiagnostics({ uri: uri, diagnostics });
}
// Listen on the connection
connection.listen();
//# sourceMappingURL=lua_language_server.js.map