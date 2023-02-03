export let API_URL: string | undefined = undefined;
export let API_KEY: string | undefined = undefined;

type Fetch = (input: RequestInfo | URL, init?: RequestInit | undefined) => Promise<Response>;

export let fetch: Fetch;

export function init(opts: {
    api_url: string,
    api_key: string,
    fetch: Fetch,
}) {
    API_URL = opts.api_url;
    API_KEY = opts.api_key;
    fetch = opts.fetch;
}
