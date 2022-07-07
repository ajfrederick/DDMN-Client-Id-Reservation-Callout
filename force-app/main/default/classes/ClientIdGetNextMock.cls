/**
 * @name ClientIdGetNextMock
 * @description Mock for ClientIdCalloutTest.cls
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
public class ClientIdGetNextMock implements HttpCalloutMock {
    
    public HttpResponse respond( HttpRequest req ){

        if( req.getHeader('access_token') != ClientIdCalloutTest.ACCESS_TOKEN ){
            throw new AccessTokenException('Invalid Access Token');
        }
        
        HttpResponse response = new HttpResponse();
        response.setHeader( 'Content-Type', 'text/html' );
        response.setBody( ClientIdCalloutTest.CLIENT_ID );
        response.setStatus('OK');
        response.setStatusCode( 200 );

        return response;
    }

    class AccessTokenException extends Exception {}
}