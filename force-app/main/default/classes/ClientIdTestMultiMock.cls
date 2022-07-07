/**
 * @name ClientIdTestMultiMock
 * @description Mock for ClientIdCalloutTest.cls. Allows for the ability to set one mock and for multiple calls. This is because the access token callout
 * is only called privately directly preceeding any client Id call
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
public class ClientIdTestMultiMock implements HttpCalloutMock {
    
    private Map<String, HttpCalloutMock> mocks {
        get {
            if( mocks == null ){
                mocks = new Map<String, HttpCalloutMock>();
            }
            return mocks;
        }
        set;
    }

    public HttpResponse respond( HttpRequest req ){

        if( !mocks.containsKey( req.getEndpoint() ) ){
            throw new MockException( 'mock does not exist' );
        }

        return mocks.get( req.getEndpoint() ).respond( req );
    }

    public void addMock( String endpointUrl, HttpCalloutMock mock ){
        mocks.put( endpointUrl, mock );
    }

    class MockException extends Exception {}
}
