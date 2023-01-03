export type UserId = string;
export type ConversationId = string;
export type LineId = string;
export type user_id = string;
export type DateTime = string;
export type User = {
    id: UserId;
    display_name: string;
};
export type ConnectionEvent = ConnectionEventUnreadMessage;
export type ConnectionEventUnreadMessage = {
    type: "UnreadMessage";
    timestamp: DateTime;
    conversation_id: ConversationId;
    from: User;
};
export type ConversationEvent = ConversationEventMessage | ConversationEventJoin | ConversationEventLeave | ConversationEventStartTyping | ConversationEventEndTyping;
export type ConversationEventMessage = {
    type: "Message";
    timestamp: DateTime;
    from: User;
    content: string;
};
export type ConversationEventJoin = {
    type: "Join";
    timestamp: DateTime;
    from: User;
};
export type ConversationEventLeave = {
    type: "Leave";
    timestamp: DateTime;
    from: User;
};
export type ConversationEventStartTyping = {
    type: "StartTyping";
    timestamp: DateTime;
    from: User;
};
export type ConversationEventEndTyping = {
    type: "EndTyping";
    timestamp: DateTime;
    from: User;
};
export type GetConnectionEventsOutput = {
    events: ConnectionEvent[];
};
export type GetConversationEventsOutput = {
    events: ConversationEvent[];
};
export type SendMessageInput = {
    content: string;
};
export type MarkReadInput = {
    conversation_id: ConversationId;
    line_id: LineId;
};
