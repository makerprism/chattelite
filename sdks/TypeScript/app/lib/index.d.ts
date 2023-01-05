import * as Types from "./generated/types";
import * as Endpoints from "./generated/endpoints";
import { init } from "./config";
declare const Chattelite: {
    Types: typeof Types;
    Endpoints: typeof Endpoints;
    init: typeof init;
};
export default Chattelite;
