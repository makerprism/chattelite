//import * as EventSourceWithHeaders from "event-source-with-headers";

import * as Utils from "./utils";
import * as Types from "./generated/types";
import * as Endpoints from "./generated/endpoints";
import { init } from "./config";


const ChatteliteClient = {
    //EventSourceWithHeaders,
    init,
    Types,
    Endpoints,
    Utils,
}

export default ChatteliteClient;
