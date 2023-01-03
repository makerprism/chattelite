export type UserId = string;
export type ConversationId = string;
export type user_id = string;
export type DateTime = string;
export type CreateUserInput = {
    id: string;
    display_name: string;
};
export type GenerateClientJwtInput = {
    user_id: string;
};
export type GenerateClientJwtOutput = {
    jwt: string;
};
export type CreateConversationInput = {
    user_ids: UserId[];
};
export type CreateConversationOutput = {
    conversation_id: ConversationId;
};
export type AddUsersToConversationInput = {
    user_ids: UserId[];
};
export type RemoveUsersFromConversationInput = {
    user_ids: UserId[];
};
