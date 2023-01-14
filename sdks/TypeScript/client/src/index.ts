//import * as EventSourceWithHeaders from "event-source-with-headers";

import * as Types from "./generated/types";
import * as Endpoints from "./generated/endpoints";
import { init } from "./config";
import EventSourceWithHeaders from "event-source-with-headers";

const ChatteliteClient = {
    EventSourceWithHeaders,
    init,
    ...Types,
    ...Endpoints,
}

export default ChatteliteClient;
