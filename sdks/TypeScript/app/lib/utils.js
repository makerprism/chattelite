"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.stringify_query = exports.postFormData = exports.del = exports.post = exports.get = void 0;
const config_1 = require("./config");
function maker_database_api_fetch(url, opts) {
    let fetch_url = config_1.API_URL + url;
    console.log(['fetch_url', fetch_url]);
    const response = (0, config_1.fetch)(fetch_url, opts).then((res) => __awaiter(this, void 0, void 0, function* () {
        console.log(res);
        switch (res.status) {
            case 200:
                return res.json();
            default:
                return res.json().then((data) => {
                    return {
                        error: true,
                        status: res.status,
                        body: data
                    };
                });
        }
    }));
    return response;
}
function get(url, opts) {
    let headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
    };
    if (opts.session_token) {
        headers['X-Access-Token'] = opts.session_token;
    }
    return maker_database_api_fetch(url, {
        headers
    });
}
exports.get = get;
function post(url, opts, body) {
    let b = body ? JSON.stringify(body) : 'null';
    let headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
    };
    if (opts.session_token) {
        headers['X-Access-Token'] = opts.session_token;
    }
    return maker_database_api_fetch(url, {
        method: 'POST',
        body: b,
        headers
    });
}
exports.post = post;
function del(url, opts) {
    let headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
    };
    if (opts.session_token) {
        headers['X-Access-Token'] = opts.session_token;
    }
    return maker_database_api_fetch(url, {
        method: 'DELETE',
        headers
    });
}
exports.del = del;
function postFormData(url, opts, formData) {
    return __awaiter(this, void 0, void 0, function* () {
        let headers = {
            Accept: 'application/json'
        };
        if (opts.session_token) {
            headers['X-Access-Token'] = opts.session_token;
        }
        return maker_database_api_fetch(url, {
            method: 'POST',
            body: formData,
            headers
        });
    });
}
exports.postFormData = postFormData;
function url_encode_add_key_value_pair(result, name, value) {
    if (value === undefined || value === null)
        return;
    result.push([encodeURIComponent(name), encodeURIComponent(value)]);
}
class GenericQueryParams {
    constructor(s) {
        this.params = s;
    }
    url_encode() {
        let result = [];
        for (let key in this.params) {
            let o = this.params[key];
            if (o === null)
                continue;
            if (typeof o === 'string' || typeof o === 'number' || typeof o === 'boolean') {
                url_encode_add_key_value_pair(result, key, o.toString());
                continue;
            }
            if (Array.isArray(o)) {
                if (o.length > 0) {
                    if (typeof o[0] === 'string' ||
                        typeof o[0] === 'number' ||
                        typeof o[0] === 'boolean') {
                        url_encode_add_key_value_pair(result, key, o.join(','));
                        continue;
                    }
                    /*if (typeof o[0] === "object" && o[0].hasOwnProperty("url_encode")) {
                        continue;
                    }*/
                }
                throw 'url_encode not implemented for ' + typeof o + ' ' + JSON.stringify(o);
            }
            if (typeof o === 'object' && o.hasOwnProperty('url_encode')) {
                for (let [k, v] of o.url_encode()) {
                    result.push([`${key}.${k}`, v]);
                }
            }
            throw 'url_encode not implemented for ' + typeof o + ' ' + JSON.stringify(o);
        }
        return result;
    }
}
function stringify_query(q) {
    let result = new GenericQueryParams(q).url_encode();
    console.log(['stringify_query', result]);
    return result.length > 0 ? `?${result.map(([k, v]) => `${k}=${v}`).join('&')}` : '';
}
exports.stringify_query = stringify_query;
exports.default = {
    get: get,
    post: post,
    postFormData: postFormData
};
