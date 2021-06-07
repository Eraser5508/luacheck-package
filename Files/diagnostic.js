"use strict";
var vscode = require('vscode');
var path = require('path');
var luacheck = require('./luacheck');
var execution = require('./execution');
// :line:range: (code) message
var diagnosticRe = /^:(\d+):(\d+)-(\d+): \(([EW])(\d+)\) (.+)$/;
function str2diagserv(str) {
    switch (str) {
        case 'E':
            return vscode.DiagnosticSeverity.Error;
        case 'W':
            return vscode.DiagnosticSeverity.Warning;
        default:
            return vscode.DiagnosticSeverity.Information;
    }
}
var DiagnosticProvider = (function () {
    function DiagnosticProvider() {
    }
    DiagnosticProvider.prototype.provideDiagnostic = function (document) {
        var _this = this;
        return this.fetchDiagnostic(document).then(function (data) { return _this.parseDiagnostic(document, data); }, function (e) {
            if (e.errorCode === execution.ErrorCode.BufferLimitExceed) {
                vscode.window.showWarningMessage('Diagnostic was interpreted due to lack of buffer size. ' +
                    'The buffer size can be increased using `luacheck.maxBuffer`. ');
            }
            return '';
        });
    };
    DiagnosticProvider.prototype.fetchDiagnostic = function (document) {
        var _a = luacheck.check(document), cmd = _a[0], args = _a[1];
        return execution.processString(cmd, args, {
            cwd: path.dirname(document.uri.fsPath),
            maxBuffer: luacheck.getConf('maxBuffer')
        }, document.getText()).then(function (result) { return result.stdout; });
    };
    DiagnosticProvider.prototype.parseDiagnostic = function (document, data) {
        var prefixLen = document.uri.fsPath.length;
        var result = [];
        data.split(/\r\n|\r|\n/).forEach(function (line) {
            line = line.substring(prefixLen);
            var matched = line.match(diagnosticRe);
            if (!matched)
                return;
            var sline = parseInt(matched[1]);
            var schar = parseInt(matched[2]);
            var echar = parseInt(matched[3]);
            var msg = matched[6];
            var warningCode = matched[5]
            var type = str2diagserv(matched[4]);
            var range = new vscode.Range(sline - 1, schar - 1, sline - 1, echar);
            result.push(new vscode.Diagnostic(range, "[" + warningCode  + "] " + msg, type));
        });
        return result;
    };
    return DiagnosticProvider;
}());
exports.DiagnosticProvider = DiagnosticProvider;
//# sourceMappingURL=diagnostic.js.map