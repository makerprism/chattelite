import * as Utils from "./utils";
import * as Types from "./generated/types";
import * as Endpoints from "./generated/endpoints";
import { init } from "./config";
import EventSourceWithHeaders from "event-source-with-headers";
declare const ChatteliteClient: {
    EventSourceWithHeaders: typeof EventSourceWithHeaders;
    init: typeof init;
    Types: typeof Types;
    Endpoints: typeof Endpoints;
    Utils: typeof Utils;
};
export default ChatteliteClient;
