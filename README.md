# websockets_from_scratch

Just a little fun project to learn what's going on under the hood with websockets.

### websockets

Similar to HTTP - websockets is a layer on top of TCP. While an HTTP response closes the connection, a websocket connection stays open. This makes websockets great for realtime functionality in chat apps, streaming, etc.

A websocket connection has the following components:

1.  HTTP GET handshake from client to server. Request has "Connection: upgrade", "Upgrade: websocket", "Sec-WebSocket-Version", and "Sec-WebSocket-Key" headers that indicates that the client is requesting a websocket connection as well as what type of response is needed.

2.  After handshake is established, client and server are free to exchange messages which are wrapped in 'frames'. Each frame contains information about whether the message is fragmented or encoded, the content type, the payload length, the masking key and the payload of the frame.

### resources

https://blog.pusher.com/websockets-from-scratch/
