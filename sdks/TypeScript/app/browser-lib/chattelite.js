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

  // src/generated/types.ts
  var types_exports = {};

  // src/generated/endpoints.ts
  var endpoints_exports = {};
  __export(endpoints_exports, {
    add_users_to_conversation: () => add_users_to_conversation,
    create_conversation: () => create_conversation,
    create_user: () => create_user,
    delete_user: () => delete_user,
    generate_client_jwt: () => generate_client_jwt,
    remove_users_from_conversation: () => remove_users_from_conversation
  });

  // src/config.ts
  var API_URL = void 0;
  function init(api_url) {
    API_URL = api_url;
  }

  // src/utils.ts
  function maker_database_api_fetch(url, opts) {
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
  function post(url, opts, body) {
    let b = body ? JSON.stringify(body) : "null";
    let headers = {
      Accept: "application/json",
      "Content-Type": "application/json"
    };
    if (opts.session_token) {
      headers["X-Access-Token"] = opts.session_token;
    }
    return maker_database_api_fetch(url, {
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
    return maker_database_api_fetch(url, {
      method: "DELETE",
      headers
    });
  }

  // src/generated/endpoints.ts
  function create_user(opts, body) {
    return post(`/users`, opts, body);
  }
  function delete_user(opts, user_id) {
    return del(`/user/${user_id}`, opts);
  }
  function generate_client_jwt(opts, body) {
    return post(`/gen-client-jwt`, opts, body);
  }
  function create_conversation(opts, body) {
    return post(`/conversations`, opts, body);
  }
  function add_users_to_conversation(opts, conversation_id, body) {
    return post(`/conversation/${conversation_id}/add-users`, opts, body);
  }
  function remove_users_from_conversation(opts, conversation_id, body) {
    return post(`/conversation/${conversation_id}/remove-users`, opts, body);
  }

  // src/index.ts
  var Chattelite = {
    Types: types_exports,
    Endpoints: endpoints_exports,
    init
  };
  var src_default = Chattelite;

  // src/browser.ts
  window["Chattelite"] = src_default;
})();
//# sourceMappingURL=chattelite.js.map
