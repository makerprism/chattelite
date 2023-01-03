export type ConversationId = string;
export type Username = string;
export type DateTime = string;
export type CreateUserInput = {
    username: string;
};
export type GenerateClientJwtInput = {
    username: string;
};
export type GenerateClientJwtOutput = {
    jwt: string;
};
export type CreateConversationInput = {
    users: Username[];
};
export type CreateConversationOutput = {
    conversation_id: ConversationId;
};
export type AddUsersToConversationInput = {
    users: Username[];
};
export type RemoveUsersFromConversationInput = {
    users: Username[];
};
