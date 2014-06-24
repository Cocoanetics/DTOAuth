DTOAuth
=======

This project aims to provide a simple OAuth client for the 3-legged OAuth 1.0a flow. 

Usage
-----

For testing the demo app please create apps for Discogs or Twitter and add the respective consumer keys and secrets in the demo's `OAuthSettings.h`

 1. Call `-requestTokenWithCompletion:` (leg 1)
 2. Get the `-userTokenAuthorizationRequest` and load it in webview, DTOAuthWebViewController is provided for this (leg 2)
 3. Extract the verifier returned from the OAuth provider once the user authorizes the app, DTOAuthWebViewController does that via delegate method.
 4. Call `-authorizeTokenWithVerifier:completion:` passing this verifier (leg 3)

License
-------

It is open source and covered by a standard 2-clause BSD license. That means you have to mention *Cocoanetics* as the original author of this code and reproduce the LICENSE text inside your app. 
