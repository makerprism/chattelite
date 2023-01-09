export let API_URL: string | undefined = undefined;

type Fetch = (input: RequestInfo | URL, init?: RequestInit | undefined) => Promise<Response>;

export let fetch: Fetch;

export function init(opts: {
    api_url: string,
    fetch: Fetch,
}) {
    API_URL = opts.api_url;
    fetch = opts.fetch;
}
