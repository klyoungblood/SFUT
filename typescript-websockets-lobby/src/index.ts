import WebSocket, { Server } from 'ws';
import * as crypto from 'crypto';
import { DurableObject } from 'cloudflare:workers';
import { ClientSocket } from './models/clientSocket';
import { LoggerHelper } from './helpers/logger-helper';
import { Message } from './models/message';
import { GameServerHandler } from './handlers/game-server-handler';
import { ProtocolHelper } from './handlers/protocol-handler';

const CONFIG_PORT = 80;

export interface Env {
	WEBSOCKET_SERVER: DurableObjectNamespace<LobbyObject>;
	SECRET_KEY: string;
	TURN_KEY: string;
}

// Formatted like a Godot Peer (int), but toString(), or else Godot will parse it as a float, not int.
// See: https://docs.godotengine.org/en/3.2/classes/class_jsonparseresult.html
function userId() {
	return Math.abs(new Int32Array(crypto.randomBytes(4).buffer)[0]).toString();
}

// Worker
export default {
	async fetch(request, env, ctx): Promise<Response> {
		// Expect to receive a WebSocket Upgrade request.
		// If there is one, accept the request and return a WebSocket Response.
		const upgradeHeader = request.headers.get('Upgrade');
		if (!upgradeHeader || upgradeHeader !== 'websocket') {
			return new Response('Durable Object expected Upgrade: websocket', {
				status: 426,
			});
		}

		// This example will refer to the same Durable Object,
		// since the name "foo" is hardcoded.
		let id = env.WEBSOCKET_SERVER.idFromName('foo');
		let stub = env.WEBSOCKET_SERVER.get(id);

		return stub.fetch(request);
	},
} satisfies ExportedHandler<Env>;

// Durable Object
export class LobbyObject extends DurableObject {
	secretKey: string;
	currentlyConnectedWebSockets: number;
	gameServer: GameServerHandler;
	turnKey: string;

	constructor(ctx: DurableObjectState, env: Env) {
		// This is reset whenever the constructor runs because
		// regular WebSockets do not survive Durable Object resets.
		//
		// WebSockets accepted via the Hibernation API can survive
		// a certain type of eviction, but we will not cover that here.
		super(ctx, env);
		this.gameServer = new GameServerHandler();
		this.currentlyConnectedWebSockets = 0;
		this.secretKey = env.SECRET_KEY;
		this.turnKey = env.TURN_KEY;
	}

	async fetch(request: Request): Promise<Response> {
		// Creates two ends of a WebSocket connection.
		const webSocketPair = new WebSocketPair();

		// AD NOTE: Trying to use client as `ws`...
		const [client, server] = Object.values(webSocketPair);

		// Calling `accept()` tells the runtime that this WebSocket is to begin terminating
		// request within the Durable Object. It has the effect of "accepting" the connection,
		// and allowing the WebSocket to send and receive messages.
		server.accept();
		this.currentlyConnectedWebSockets += 1;

		// TODO: better typing?
		// AD NOTE: Trying to use server as `ws`...
		const clientSocket: ClientSocket = new ClientSocket(server, userId());
		this.gameServer.addClient(clientSocket);

		// // Upon receiving a message from the client, the server replies with the same message,
		// // and the total number of connections with the "[Durable Object]: " prefix
		server.addEventListener('message', (event: MessageEvent) => {
			// if message type...
			// server.send(`[Durable Object] currentlyConnectedWebSockets: ${this.currentlyConnectedWebSockets}`);
			const decodeMessage = new TextDecoder().decode(event.data as any);
			const parsedMessage: Message = Message.fromString(decodeMessage.toString());
			ProtocolHelper.parseReceivingMessage(this.gameServer, clientSocket, parsedMessage, this.secretKey, this.turnKey);
		});

		// // If the client closes the connection, the runtime will close the connection too.

		// TODO: Not sure who needs to close here...
		server.addEventListener('close', (cls: CloseEvent) => {
			// this.currentlyConnectedWebSockets -= 1;
			this.gameServer.removeClient(clientSocket.id);
			LoggerHelper.logInfo(`Connection closed for ${clientSocket.id}`);
			// client.close();
			server.close();
		});

		// TODO: Not sure who needs to close here
		server.addEventListener('error', (err) => {
			// this.gameServer.removeClient(clientSocket.id);
			LoggerHelper.logWarn(`WS Error for ${clientSocket.id}: ${err.message}`);
			// client.close();
			// server.close();
		});

		return new Response(null, {
			status: 101,
			webSocket: client,
		});
	}
}
