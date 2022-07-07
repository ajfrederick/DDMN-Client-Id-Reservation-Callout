/**
 * @name ClientIdReserveMock
 * @description Mock for ClientIdCalloutTest.cls
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
public class ClientIdReserveMock implements HttpCalloutMock {
    
    public HttpResponse respond( HttpRequest req ){
        
        HttpResponse response = new HttpResponse();
        response.setHeader( 'Content-Type', 'text/html' );
        response.setBody( ClientIdCalloutTest.RESERVE_SUCCESS_MESSAGE );
        response.setStatus('OK');
        response.setStatusCode( 200 );

        return response;
    }
}
