"use strict";
(() => {
  var __defProp = Object.defineProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __async = (__this, __arguments, generator) => {
    return new Promise((resolve, reject) => {
      var fulfilled = (value) => {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      };
      var rejected = (value) => {
        try {
          step(generator.throw(value));
        } catch (e) {
          reject(e);
        }
      };
      var step = (x) => x.done ? resolve(x.value) : Promise.resolve(x.value).then(fulfilled, rejected);
      step((generator = generator.apply(__this, __arguments)).next());
    });
  };

  // src/utils.ts
  var utils_exports = {};
  __export(utils_exports, {
    default: () => utils_default,
    del: () => del,
    get: () => get,
    post: () => post,
    postFormData: () => postFormData,
    stringify_query: () => stringify_query
  });

  // src/config.ts
  var API_URL = void 0;
  function init(api_url) {
    API_URL = api_url;
  }

  // src/utils.ts
  function api_fetch(url, opts) {
    let fetch_url = API_URL + url;
    console.log(["fetch_url", fetch_url]);
    const response = fetch(fetch_url, opts).then((res) => __async(this, null, function* () {
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
      Accept: "application/json",
      "Content-Type": "application/json"
    };
    if (opts.session_token) {
      headers["X-Access-Token"] = opts.session_token;
    }
    return api_fetch(url, {
      headers
    });
  }
  function post(url, opts, body) {
    let b = body ? JSON.stringify(body) : "null";
    let headers = {
      Accept: "application/json",
      "Content-Type": "application/json"
    };
    if (opts.session_token) {
      headers["X-Access-Token"] = opts.session_token;
    }
    return api_fetch(url, {
      method: "POST",
      body: b,
      headers
    });
  }
  function del(url, opts) {
    let headers = {
      Accept: "application/json",
      "Content-Type": "application/json"
    };
    if (opts.session_token) {
      headers["X-Access-Token"] = opts.session_token;
    }
    return api_fetch(url, {
      method: "DELETE",
      headers
    });
  }
  function postFormData(url, opts, formData) {
    return __async(this, null, function* () {
      let headers = {
        Accept: "application/json"
      };
      if (opts.session_token) {
        headers["X-Access-Token"] = opts.session_token;
      }
      return api_fetch(url, {
        method: "POST",
        body: formData,
        headers
      });
    });
  }
  function url_encode_add_key_value_pair(result, name, value) {
    if (value === void 0 || value === null)
      return;
    result.push([encodeURIComponent(name), encodeURIComponent(value)]);
  }
  var GenericQueryParams = class {
    constructor(s) {
      this.params = s;
    }
    url_encode() {
      let result = [];
      for (let key in this.params) {
        let o = this.params[key];
        if (o === null)
          continue;
        if (typeof o === "string" || typeof o === "number" || typeof o === "boolean") {
          url_encode_add_key_value_pair(result, key, o.toString());
          continue;
        }
        if (Array.isArray(o)) {
          if (o.length > 0) {
            if (typeof o[0] === "string" || typeof o[0] === "number" || typeof o[0] === "boolean") {
              url_encode_add_key_value_pair(result, key, o.join(","));
              continue;
            }
          }
          throw "url_encode not implemented for " + typeof o + " " + JSON.stringify(o);
        }
        if (typeof o === "object" && o.hasOwnProperty("url_encode")) {
          for (let [k, v] of o.url_encode()) {
            result.push([`${key}.${k}`, v]);
          }
        }
        throw "url_encode not implemented for " + typeof o + " " + JSON.stringify(o);
      }
      return result;
    }
  };
  function stringify_query(q) {
    let result = new GenericQueryParams(q).url_encode();
    console.log(["stringify_query", result]);
    return result.length > 0 ? `?${result.map(([k, v]) => `${k}=${v}`).join("&")}` : "";
  }
  var utils_default = {
    get,
    post,
    postFormData
  };

  // src/generated/types.ts
  var types_exports = {};

  // src/generated/endpoints.ts
  var endpoints_exports = {};
  __export(endpoints_exports, {
    get_connection_events: () => get_connection_events,
    get_conversation_events: () => get_conversation_events,
    mark_read: () => mark_read,
    send_message: () => send_message,
    start_typing: () => start_typing,
    stop_typing: () => stop_typing
  });
  function get_connection_events(opts) {
    return get(`/events`, opts);
  }
  function get_conversation_events(opts, conversation_id) {
    return get(`/conversation/${conversation_id}/events`, opts);
  }
  function send_message(opts, conversation_id, body) {
    return post(`/conversation/${conversation_id}`, opts, body);
  }
  function start_typing(opts, conversation_id, body) {
    return post(`/conversation/${conversation_id}/start-typing`, opts, body);
  }
  function stop_typing(opts, conversation_id, body) {
    return post(`/conversation/${conversation_id}/stop-typing`, opts, body);
  }
  function mark_read(opts, body) {
    return post(`/read`, opts, body);
  }

  // src/index.ts
  var ChatteliteClient = {
    init,
    Types: types_exports,
    Endpoints: endpoints_exports,
    Utils: utils_exports
  };
  var src_default = ChatteliteClient;

  // src/browser.ts
  window["ChatteliteClient"] = src_default;
})();
//# sourceMappingURL=chattelite-client.js.map
