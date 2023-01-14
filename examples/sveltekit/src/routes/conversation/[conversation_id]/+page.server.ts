import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async ({ params }) => {
    return {
        conversation_id: params.conversation_id,
    };
}
