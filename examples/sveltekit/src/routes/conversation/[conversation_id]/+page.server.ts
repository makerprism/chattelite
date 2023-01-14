import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async ({ params }) => {
    return {
        conversation_id: params.conversation_id,
    };
}

/*
let c = await Chattelite.create_conversation({ session_token: API_KEY}, { user_ids: [USER_ID] });
if ("error" in c) {
    throw "failed to create conversation"
}
CONVERSATION_ID = c.conversation_id;
*/
