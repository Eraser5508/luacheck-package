'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const path = require("path");
const fs = require("fs");
const LuaVM = require('./lua.vm');
const luacheck_module_path = path.normalize(path.join(__dirname, '../luamodule/'));
class luacheck {
    constructor(L) {
        this.L = L;
        L.mount(luacheck_module_path, "/luacheck");
        L.execute("package.path = package.path..';/luacheck/?.lua;/luacheck/?/init.lua'");
        L.execute('luacheck = require("luacheck");');
        var FS = L.filesystem();
        // Create 'lfs' library
        var lfs = {
            currentdir: function () { return FS.cwd(); },
            attributes: function (type) {
                let path = this;
                if (type == 'mode') {
                    try {
                        var stat = FS.stat(path);
                        if (!stat) {
                            return null;
                        }
                        var m = stat.mode;
                        if (FS.isFile(m)) {
                            return "file";
                        }
                        if (FS.isDir(m)) {
                            return "directory";
                        }
                    }
                    catch (e) {
                    }
                    return "";
                }
                else {
                    return 0;
                }
            },
            dir: function () { return {}; },
        };
        L.push(lfs);
        L.setglobal("lfs");
        L.execute("package.loaded.lfs = lfs");
        L.execute('luacheck_config = require("luacheck.config");');
    }
    invokeCheckFunction(fn, source, max_reports, convert_column) {
        function createReport(luadata) {
            let report = {
                code: "",
                column: 0,
                end_column: 0,
                line: 0,
                message: "",
            };
            let members = ["code", "column", "end_column", "line", "name",
                "msg", "message", "module", "indirect", "func", "recursive",
                "mutually_recursive", "field", "prev_line", "label"];
            for (let name of members) {
                let value = luadata.get(name);
                if (value !== undefined) {
                    if (!value.free) {
                        report[name] = value;
                    }
                    else {
                        value.free();
                    }
                }
            }
            if (convert_column) {
                report.column = convert_column(report.line, report.column);
                report.end_column = convert_column(report.line, report.end_column);
            }
            return report;
        }
        let reports = [];
        try {
            let lreports = fn.invoke([source], 1)[0];
            for (var i = 1; i <= max_reports; i++) {
                let lreport = lreports.get(i);
                if (!lreport) {
                    break;
                }
                let rt = createReport(lreport);
                lreport.free();
                reports.push(rt);
            }
            lreports.free();
        }
        catch (e) {
            console.error(e);
        }
        finally {
        }
        return JSON.parse(JSON.stringify(reports));
    }
    check(filepath, source_text = null, max_reports = 100, utf8position = false) {
        let lines = null;
        if (source_text) {
            lines = source_text.split(/\r?\n/g);
        }
        else {
            lines = fs.readFileSync(filepath, "utf-8").split(/\r?\n/g);
        }
        if (fs.existsSync(filepath)) {
            let full_path = path.resolve(filepath);
            let token = path.parse(full_path);
            let cwd = path.dirname(full_path);
            let filename = path.basename(full_path);
            let mountdir = cwd;
            try {
                while (true) {
                    let root = mountdir.split(path.sep).slice(0, -1).join(path.sep);
                    // Handle windows filesystem root like D:\
                    if (token.root.startsWith(root)) {
                        this.L.chroot(token.root);
                        break;
                    }
                    this.L.chroot(root);
                    mountdir = root;
                }
            }
            catch (e) {
                this.L.chroot(mountdir);
            }
            this.L.chdir(cwd);
            filepath = path.relative(cwd, filepath);
        }
        function convertColumn(line, column) {
            let t = lines[line - 1];
            let utf8len = 0;
            let codeCount = 0;
            for (codeCount = 0; codeCount < t.length; codeCount++) {
                let codepoint = t.codePointAt(codeCount);
                if (codepoint <= 0x7F) {
                    utf8len += 1;
                }
                else if (codepoint <= 0x07FF) {
                    utf8len += 2;
                }
                else if (codepoint <= 0xFFFF) {
                    utf8len += 3;
                }
                else if (codepoint <= 0x1FFFFF) {
                    utf8len += 4;
                }
                if (column <= utf8len) {
                    break;
                }
            }
            return codeCount + 1;
        }
        if (source_text) {
            let file_checker = this.L.load('local options = luacheck_config.load_config().options ' +
                '  local reports = luacheck.check_strings({...},options)[1] ' +
                '  for i = 1,#reports do ' +
                '   reports[i]["message"] =luacheck.get_message(reports[i]) ' +
                '  end ' +
                ' return reports ');
            let reports = this.invokeCheckFunction(file_checker, source_text, max_reports, convertColumn);
            file_checker.free();
            return reports;
        }
        else {
            let strings_checker = this.L.load('local options = luacheck_config.load_config().options ' +
                '  local reports = luacheck.check_files({...},options)[1] ' +
                '  for i = 1,#reports do ' +
                '   reports[i]["message"] =luacheck.get_message(reports[i]) ' +
                '  end ' +
                ' return reports ');
            let reports = this.invokeCheckFunction(strings_checker, filepath, max_reports, convertColumn);
            strings_checker.free();
            return reports;
        }
    }
}
exports.luacheck = luacheck;
//# sourceMappingURL=luacheck.js.map