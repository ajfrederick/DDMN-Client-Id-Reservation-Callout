/**
* @name ClientIdCalloutGetNext
*
* @description this calss was built to help replace wv6_getNextavailableClientIdentifier and wv6_reserveClientIdentifier. 
* These callouts makes a callout directly to DDMI. It skips the call to the reverse proxy at DDMN. 
*
* @author Creed Interactive (Andrew Frederick) March 2022
*/
public class ClientIdCalloutGetNext {

/**
* FIELDS
*/ 

    private static final String METHOD_NAME = 'nextAvailableClientIdentifier';

    private static String planAcronym {
        get {

            if( planAcronym == null ){
                planAcronym = 'DDMN';
            }

            return planAcronym;
        }
        set {
            planAcronym = EncodingUtil.urlEncode( value, 'UTF-8' );
        }
    }

/**
* INVOCABLE METHODS
*/

    /**
     * @name getNext
     * @description this method is called in the "Reserve Client Identifier" Flow. It makes a callout to a DDMI api. It gets the next available Client Id
     * @param ClientIdGetNextRequest[] reqs
     * @return ClientIdGetNextResponse[] responses
     */
    @InvocableMethod(label='Get Next Available Client Identifier New' description='Callout to DDMI api for the next available client Number')
    public static ClientIdGetNextResponse[] getNext( ClientIdGetNextRequest[] reqs ){
        
        planAcronym = reqs.size() > 0 ? reqs[0].planAcronym : planAcronym;

        ClientIdGetNextHttpHandler httpHandler = new ClientIdGetNextHttpHandler();

        try {

            HttpRequest request = ClientIdCallout.getClientIdRequest();

            httpHandler.send( request );

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }

        ClientIdGetNextResponse response = new ClientIdGetNextResponse();
        response.nextAvailableClientId = httpHandler.getReponseBody();
        response.statusCode = httpHandler.getStatusCode();
        response.status = httpHandler.getStatus();
        
        ClientIdGetNextResponse[] responses = new ClientIdGetNextResponse[]{};
        responses.add( response );

        return responses;
    }

/**
* CLASSES
*/

    public class ClientIdGetNextHttpHandler extends HttpHandler {

        public override String getEndpoint(){
            return ClientIdCallout.getRequestURL() + '/' + planAcronym + '/' + METHOD_NAME;
        }
    }

    public class ClientIdGetNextRequest {
        @InvocableVariable
        public String planAcronym;  
    }

    public class ClientIdGetNextResponse {
        @InvocableVariable
        public String nextAvailableClientId; 
        
        @InvocableVariable
        public String status;
        
        @InvocableVariable
        public Integer statusCode;
    }

/**
* EXCEPTION CLASSES
*/

    class InvocableException extends Exception {}

}
