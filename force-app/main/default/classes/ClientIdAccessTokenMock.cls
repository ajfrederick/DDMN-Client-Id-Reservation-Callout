/**
 * @name ClientIdAccessTokenMock
 * @description Mock for ClientIdCalloutTest.cls
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
public class ClientIdAccessTokenMock implements HttpCalloutMock {
    
    public HttpResponse respond( HttpRequest req ){
        
        AccessTokenResponse accessTokenResponse = new AccessTokenResponse();
        accessTokenResponse.access_token = ClientIdCalloutTest.ACCESS_TOKEN;
        accessTokenResponse.expires_in = 3600;
        
        HttpResponse response = new HttpResponse();
        response.setHeader( 'Content-Type', 'application/json' );
        response.setBody( JSON.serialize(accessTokenResponse) );
        response.setStatus('OK');
        response.setStatusCode( 200 );

        return response;
    }

    class AccessTokenResponse {
        String access_token {get;set;}
        Integer expires_in {get;set;}
    }
}
