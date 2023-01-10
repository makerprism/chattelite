import "chattelite";
import polka from "polka";
import sirv from "sirv";
import Chattelite from "chattelite";
import fetch from 'node-fetch';
import { json } from 'body-parser';

const USER_ID = "test";
let API_KEY = "53whn530h8n530hietpg3oq5pmupq35mupi356mu";

let CONVERSATION_ID: string;


async function start() {
    Chattelite.init({ api_url: "http://127.0.0.1:8000", fetch: fetch as any});

    await Chattelite.Endpoints.create_user({ session_token: API_KEY}, { id: USER_ID, display_name: USER_ID });

    let c = await Chattelite.Endpoints.create_conversation({ session_token: API_KEY}, { user_ids: [USER_ID] });
    if ("error" in c) {
        throw "failed to create conversation"
    }
    CONVERSATION_ID = c.conversation_id;
    
    const static_html = sirv('static');
    const chattelite_min_js = sirv('node_modules/chattelite-client/browser-lib');
    
    polka()
        .use(json())
        .use(static_html)
        .use(chattelite_min_js)
        .get('/login', async (req, res) => {
            let jwt = await Chattelite.Endpoints.generate_client_jwt({ session_token: API_KEY }, { user_id: USER_ID });
            
            if ("error" in jwt) {
                res.status(500);
                return res;
            }
            
            res.end(JSON.stringify({
                jwt: jwt.jwt,
                conversation_id: CONVERSATION_ID,
            }))
        })
        .post('/join', async (req, res) => {
            console.log("body", req.body);
            Chattelite.Endpoints.add_users_to_conversation({session_token: API_KEY}, req.body.conversation_id, { user_ids: [USER_ID] })
            res.end("ok")
        })
        .post('/leave', async (req, res) => {
            Chattelite.Endpoints.remove_users_from_conversation({session_token: API_KEY}, req.body.conversation_id, { user_ids: [USER_ID] })
            res.end("ok")
        })
        .listen(3000, (err: any) => {
            if (err) throw err;
            console.log(`> Running on localhost:3000`);
        });
}

start()
