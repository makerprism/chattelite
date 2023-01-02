export type ConversationId = string;
export type LineId = string;
export type Username = string;
export type DateTime = string;
export type ConnectionEvent = ConnectionEventUnreadMessage;
export type ConnectionEventUnreadMessage = {
    type: "UnreadMessage";
    timestamp: DateTime;
    conversation_id: ConversationId;
    from: Username;
};
export type ConversationEvent = ConversationEventMessage | ConversationEventJoin | ConversationEventLeave | ConversationEventStartTyping | ConversationEventEndTyping;
export type ConversationEventMessage = {
    type: "Message";
    timestamp: DateTime;
    from: Username;
    content: string;
};
export type ConversationEventJoin = {
    type: "Join";
    timestamp: DateTime;
    from: Username;
};
export type ConversationEventLeave = {
    type: "Leave";
    timestamp: DateTime;
    from: Username;
};
export type ConversationEventStartTyping = {
    type: "StartTyping";
    timestamp: DateTime;
    from: Username;
};
export type ConversationEventEndTyping = {
    type: "EndTyping";
    timestamp: DateTime;
    from: Username;
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
