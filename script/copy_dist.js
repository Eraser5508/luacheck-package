const fs = require('fs-extra')
const path = require('path')

const extension_dir = path.normalize(path.join(__dirname, '../'))

fs.copySync(path.join(extension_dir,'third_party/lua.vm.js/dist/lua.vm.js'), path.join(extension_dir,'out/src/lua.vm.js'));
fs.copySync(path.join(extension_dir,'third_party/luacheck/src/luacheck'), path.join(extension_dir,'out/luamodule/luacheck'));