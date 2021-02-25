'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const vscode = require("vscode");
const path = require("path");
const vscode_languageclient_1 = require("vscode-languageclient");
function activate(context) {
    let serverModule = context.asAbsolutePath(path.join('out', 'src', 'lua_language_server.js'));
    let debugOptions = {};
    let serverOptions = {
        run: { module: serverModule, transport: vscode_languageclient_1.TransportKind.ipc },
        debug: { module: serverModule, transport: vscode_languageclient_1.TransportKind.ipc, options: debugOptions }
    };
    let clientOptions = {
        documentSelector: ['lua'],
        synchronize: {
            configurationSection: 'luacheck',
            fileEvents: vscode.workspace.createFileSystemWatcher('**/.luacheckrc')
        }
    };
    let disposable = new vscode_languageclient_1.LanguageClient('luacheck', 'Language Server Lua', serverOptions, clientOptions).start();
    context.subscriptions.push(disposable);
}
exports.activate = activate;
// this method is called when your extension is deactivated
function deactivate() {
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map