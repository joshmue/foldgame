# wsecho

This Dockerfile builds a slightly patched version of the [Gorilla "chat" example](https://github.com/gorilla/websocket/tree/78cf1bc733a927f673fd1988a25256b425552a8a/examples/chat).
The patch removes the message size limit as many messages contain the whole shared state.
That should be okay if access to the server is restricted.
