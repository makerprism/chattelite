export let API_URL: string | undefined = undefined;
export let JWT: string | undefined = undefined;

export function init(opts: {
    api_url: string;
    jwt: string;
}) {
    API_URL = opts.api_url;
    JWT = opts.jwt;
}

export function set_jwt(jwt: string) {
    JWT = jwt;
}
