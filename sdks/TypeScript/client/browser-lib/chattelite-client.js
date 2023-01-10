"use strict";
(() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));
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

  // ../../../../event-source-with-headers/lib/index.js
  var require_lib = __commonJS({
    "../../../../event-source-with-headers/lib/index.js"() {
      "use strict";
      (() => {
        var f = (i) => decodeURIComponent(escape(i)), v = (i) => i.replace(/\r\n|\r/g, `
`), h = class extends EventTarget {
          constructor(t, e) {
            super();
            this.CONNECTING = 0;
            this.OPEN = 1;
            this.CLOSED = 2;
            this.withCredentials = false;
            this.headers = {};
            this.lastEventId = "";
            this.reconnectionTime = 2e3;
            this.responseTextCursor = 0;
            this.eventTypeBuffer = "";
            this.idBuffer = "";
            this.dataBuffer = "";
            this.canReconnect = true;
            this.url = t, this.withCredentials = Boolean(e && e.withCredentials), e && e.headers && (this.headers = e.headers), this.addEventListener("error", (s) => {
              this.onerror && this.onerror(s);
            }), this.addEventListener("message", (s) => {
              this.onmessage && this.onmessage(s);
            }), this.addEventListener("open", (s) => {
              this.onopen && this.onopen(s);
            }), this.connect();
          }
          announceConnection() {
            this.readyState = this.OPEN, this.dispatchEvent(new Event("open")), this.responseTextCursor = 0;
          }
          connect(t = this.url) {
            this.readyState = this.CONNECTING;
            let e = this.xhr = new XMLHttpRequest();
            e.open("GET", t, true);
            for (let s in this.headers)
              e.setRequestHeader(s, this.headers[s]);
            e.setRequestHeader("Accept", "text/event-stream"), e.setRequestHeader("Cache-Control", "no-cache"), this.lastEventId && e.setRequestHeader("Last-Event-ID", this.lastEventId), e.onreadystatechange = () => {
              if (!(e.readyState <= 1 || this.readyState === this.CLOSED)) {
                if (e.readyState === 4) {
                  this.reestablishConnection();
                  return;
                }
                switch (e.status) {
                  case 200:
                    this.handleConnection(e), this.interpretStream(e);
                    break;
                  case 204:
                    this.canReconnect = false;
                    break;
                  case 301:
                  case 307:
                    let s = e.getResponseHeader("Location");
                    this.failConnection(e, true), s && this.connect(s);
                    break;
                  default:
                    this.failConnection(e);
                }
              }
            }, e.send();
          }
          dispatchMessageEvent(t) {
            if (this.lastEventId = this.idBuffer, this.dataBuffer === "") {
              this.eventTypeBuffer = "";
              return;
            }
            this.dataBuffer[this.dataBuffer.length - 1] === `
` && (this.dataBuffer = this.dataBuffer.slice(0, -1));
            let e = this.eventTypeBuffer || "message", s = new MessageEvent(e, { data: this.dataBuffer, origin: t, lastEventId: this.lastEventId });
            this.eventTypeBuffer = "", this.dataBuffer = "", this.dispatchEvent(s);
          }
          handleConnection(t) {
            if (this.readyState === this.CONNECTING) {
              let e = t.getResponseHeader("Content-Type");
              e && e.toLowerCase() === "text/event-stream" ? this.announceConnection() : this.failConnection(t);
            }
          }
          failConnection(t, e = false) {
            this.readyState = this.CLOSED, e || this.dispatchEvent(new Event("error")), this.canReconnect = false, t.abort();
          }
          interpretStream(t) {
            if (this.readyState !== this.OPEN)
              return;
            let e = "";
            try {
              e = t.responseText;
            } catch (r) {
              return;
            }
            let s = e.substring(this.responseTextCursor);
            this.responseTextCursor = e.length;
            let d = v(f(s)).split(`
`);
            for (let r = 0; r < d.length; r++) {
              let n = d[r];
              if (n === "")
                this.dispatchMessageEvent(t.responseURL);
              else {
                let a = n.indexOf(":");
                if (a !== 0)
                  if (a !== -1) {
                    let l = n.substring(0, a), o = n.substring(a + 1), u = o.indexOf(" ") === 0 ? o.slice(1) : o;
                    this.processField({ field: l, value: u });
                  } else
                    this.processField({ field: n, value: "" });
              }
            }
          }
          processField(t) {
            switch (t.field) {
              case "event":
                this.eventTypeBuffer = t.value;
                break;
              case "data":
                this.dataBuffer += `${t.value}
`;
                break;
              case "id":
                t.value.indexOf("\0") === -1 && (this.idBuffer = t.value);
                break;
              case "retry":
                let e = +t.value;
                Number.isInteger(e) && (this.reconnectionTime = e);
            }
          }
          reestablishConnection() {
            this.readyState === this.CLOSED || !this.canReconnect || (this.readyState = this.CONNECTING, this.dispatchEvent(new Event("error")), setTimeout(() => {
              this.readyState === this.CONNECTING && this.connect();
            }, this.reconnectionTime));
          }
          close() {
            this.readyState = this.CLOSED, this.xhr && this.xhr.abort();
          }
        }, c = h;
        window.EventSourceWithHeaders = c;
      })();
    }
  });

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
  var import_event_source_with_headers = __toESM(require_lib());
  var ChatteliteClient = {
    EventSourceWithHeaders: import_event_source_with_headers.default,
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
