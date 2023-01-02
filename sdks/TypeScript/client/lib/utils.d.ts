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
export type ApiResponseError<E> = BaseError & (NotFound | NotAuthenticated | Forbidden | BadRequest | InternalError | (E extends Object ? {
    body: E;
} : {}));
export declare function get(url: string, opts: {
    session_token?: string;
}): Promise<any>;
export declare function post(url: string, opts: {
    session_token?: string;
}, body?: any): Promise<any>;
export declare function del(url: string, opts: {
    session_token?: string;
}): Promise<any>;
export declare function postFormData(url: string, opts: {
    session_token: string;
}, formData: FormData): Promise<any>;
export declare function stringify_query(q: any): string;
declare const _default: {
    get: typeof get;
    post: typeof post;
    postFormData: typeof postFormData;
};
export default _default;
