export declare let API_URL: string | undefined;
type Fetch = (input: RequestInfo | URL, init?: RequestInit | undefined) => Promise<Response>;
export declare let fetch: Fetch;
export declare function init(opts: {
    api_url: string;
    fetch: Fetch;
}): void;
export {};
