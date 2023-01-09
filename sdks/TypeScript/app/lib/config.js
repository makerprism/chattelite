"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.init = exports.fetch = exports.API_URL = void 0;
exports.API_URL = undefined;
function init(opts) {
    exports.API_URL = opts.api_url;
    exports.fetch = opts.fetch;
}
exports.init = init;
