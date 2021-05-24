"use strict";
var vscode = require('vscode');
var configuration = require("./configuration");
var diagnostic_1 = require('./diagnostic');
var LUA_MODE = [
    { language: 'lua', scheme: 'file' }
];
var collection = vscode.languages.createDiagnosticCollection('lua');
function registerDiagnosticProvider(selector, provider, subscriptions) {
    var clearDiagnostics = function (document) {
        if (vscode.languages.match(selector, document)) {
            var uri = document.uri;
            collection.set(uri, null);
        }
    };
    var lint = function (document) {
        if (vscode.languages.match(selector, document)) {
            var uri_1 = document.uri;
            provider.provideDiagnostic(document).then(function (diagnostics) { return collection.set(uri_1, diagnostics); });
        }
    };
    vscode.workspace.onDidOpenTextDocument(function (document) { return lint(document); }, null, subscriptions);
    vscode.workspace.onDidCloseTextDocument(function (document) { return clearDiagnostics(document); }, null, subscriptions);
    vscode.window.onDidChangeActiveTextEditor(function (editor) {
        if (editor)
            lint(editor.document);
    }, null, subscriptions);
    vscode.workspace.onDidChangeConfiguration(function () {
        if (vscode.window.activeTextEditor) {
            lint(vscode.window.activeTextEditor.document);
        }
    }, null, subscriptions);
    if (vscode.window.activeTextEditor) {
        lint(vscode.window.activeTextEditor.document);
    }
    vscode.workspace.onDidSaveTextDocument(function ()
    {
        lint(vscode.window.activeTextEditor.document);
    }, null, subscriptions);
}
function activate(context) {
    var confTester = new configuration.ConfigurationTester;
    context.subscriptions.push(confTester);
    vscode.window.onDidChangeActiveTextEditor(function (editor) { return confTester.test(); }, null, context.subscriptions);
    var diagnosticProvider = new diagnostic_1.DiagnosticProvider;
    registerDiagnosticProvider(LUA_MODE, diagnosticProvider, context.subscriptions);
}
exports.activate = activate;
function deactivate() {
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map