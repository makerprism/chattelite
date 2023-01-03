import { API_URL } from "./config";

export type ApiResponse<S, E> = S | ApiResponseError<E>;
type BaseError = {
    error: true;
    status: number;
    body: {
        title: string;
        detail: string;
    };
};

type NotFound = {
    type: 'NotFound';
    status: 404;
};

type NotAuthenticated = {
    type: 'NotAuthenticated';
    status: 401;
};

type Forbidden = {
    type: 'Forbidden';
    body: {
        message: string;
    };
    status: 403;
};

type BadRequest = {
    type: 'BadRequest';
    body: {
        message: string;
    };
    status: 400;
};

type InternalError = {
    type: 'InternalError';
    body: {
        message: string;
    };
    status: 500;
};

export type ApiResponseError<E> = BaseError &
    (
        | NotFound
        | NotAuthenticated
        | Forbidden
        | BadRequest
        | InternalError
        | (E extends Object ? { body: E } : {})
    );

function maker_database_api_fetch(url: string, opts: any): Promise<ApiResponse<any, any>> {
    let fetch_url = API_URL + url;
    console.log(['fetch_url', fetch_url]);
    const response = fetch(fetch_url, opts).then(async (res: Response) => {
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
    });

    return response;
}

type ApiHeaders = {
    Accept: string;
    'Content-Type'?: string;
    'X-Access-Token'?: string;
};

export function get(url: string, opts: { session_token?: string }) {
    let headers: ApiHeaders = {
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

export function post(url: string, opts: { session_token?: string }, body?: any) {
    let b = body ? JSON.stringify(body) : 'null';
    let headers: ApiHeaders = {
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

export function del(url: string, opts: { session_token?: string }) {
    let headers: ApiHeaders = {
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

export async function postFormData(
    url: string,
    opts: {
        session_token: string;
    },
    formData: FormData
) {
    let headers: ApiHeaders = {
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
}

function url_encode_add_key_value_pair(
    result: [string, string][],
    name: string,
    value: string
): void {
    if (value === undefined || value === null) return;
    result.push([encodeURIComponent(name), encodeURIComponent(value)]);
}

interface QueryParamsInterface {
    params: { [key: string]: string | number | boolean | QueryParamsInterface };
    url_encode(): [string, string][];
}

class GenericQueryParams implements QueryParamsInterface {
    params: { [key: string]: string | number | boolean | QueryParamsInterface };

    constructor(s: { [key: string]: string | number | boolean | QueryParamsInterface }) {
        this.params = s;
    }

    url_encode(): [string, string][] {
        let result: [string, string][] = [];
        for (let key in this.params) {
            let o = this.params[key];
            if (o === null) continue;
            if (typeof o === 'string' || typeof o === 'number' || typeof o === 'boolean') {
                url_encode_add_key_value_pair(result, key, o.toString());
                continue;
            }
            if (Array.isArray(o)) {
                if (o.length > 0) {
                    if (
                        typeof o[0] === 'string' ||
                        typeof o[0] === 'number' ||
                        typeof o[0] === 'boolean'
                    ) {
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

export function stringify_query(q: any): string {
    let result = new GenericQueryParams(q).url_encode();
    console.log(['stringify_query', result]);
    return result.length > 0 ? `?${result.map(([k, v]) => `${k}=${v}`).join('&')}` : '';
}

export default {
    get: get,
    post: post,
    postFormData: postFormData
};
