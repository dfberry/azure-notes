import { app, InvocationContext } from "@azure/functions";

export async function eventHubTrigger(messages: unknown | unknown[], context: InvocationContext): Promise<void> {
    if (Array.isArray(messages)) {
        context.log(`Event hub function processed ${messages.length} messages`);
        for (const message of messages) {
            context.log('Event hub message:', message);
        }
    } else {
        context.log('Event hub function processed message:', messages);
    }
}

app.eventHub('eventHubTrigger', {
    connection: '%connection%',
    eventHubName: 'samples-workitems',
    cardinality: 'many',
    handler: eventHubTrigger
});
