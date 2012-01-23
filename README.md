# Wildcloud - Websockets

Service providing websockets to applications deployed in Wildcloud platform

## Status

Proof of concept implementation.

The service does not **yet** implement the interface as described below.

## Client interface

* SockJS

## Interface

Application authorizes client with _secret_ application id and custom client id. The service returns socket_id, that
should be used for identifying that specific client (e.g. user of a web application).

    POST /authorize/application_id/client_id

with parameters in it's body, encoded as JSON.

    {"callback":"http://www.yourapplication.com/ws/callback"}

To the callback url, a message published by client to the service, will be forwarded

    POST http://www.yourapplication.com/ws/callback

with content of the message as the request body with other parameters encoded as JSON

    {"message": "some message", "session": "session_id", "client": "client_id"}

where session id represent single connection between the client and this service (e.g. one window or tab in a browser).

To publish a message, the application posts a request to the service with socket_id and optional session_id

    POST /publish/socket_id

or

    POST /publish/socket_id/session_id

with JSON encoded body containing the message and optional parameters.

    {"message": "some message"}

The service then forwards the message to the client (all sessions or just a specific one).

On the client-side the user connects using SockJS to the server and specifies the already authorized socket_id

    var socket = new SockJS('http://ws.your_server.com/socket_id');

## Support

* Transports
    * Websockets
    * XHR-Streaming
    * Iframe-EventSource
    * Iframe-Htmlfile
    * XHR-Polling
    * Iframe-XHR-Polling
* Browsers
    * MacOSX
        * Chromium - OK
        * Firefox - broken on XHR polling
        * Opera - broken
        * Safari - not tested
        * Camino
    * Linux - not tested
        * Chromium
        * Firefox
        * Opera
        * Epiphany
        * Konqueror
    * Windows - not tested
        * Chromium
        * Firefox
        * Opera
        * Safari
        * Internet explorer
    * Solaris - not tested
    * BSDs - not tested
    * Android - not tested
        * Android browser
        * Firefox
        * Opera
    * iOS - not tested
        * Safari
    * WP7 - not tested
        * Internet explorer mobile

## License

Project is licensed under the terms of the Apache 2 License.
