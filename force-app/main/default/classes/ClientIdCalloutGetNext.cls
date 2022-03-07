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

    @InvocableMethod(label='Get Next Available Client Identifier New' description='Callout to DDMI api for the next available client Number')
    public static ClientIdGetNextResponse[] getNext( ClientIdGetNextRequest[] reqs ){
        
        planAcronym = reqs.size() > 0 ? reqs[0].planAcronym : planAcronym;

        ClientIdGetNextResponse[] responses = new ClientIdGetNextResponse[]{};

        try {

            HttpRequest request = ClientIdCallout.getClientIdRequest();

            ClientIdGetNextHttpHandler handler = new ClientIdGetNextHttpHandler();
            handler.send( request );
            
            responses.add( handler.getParsedResponse() );

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }

        return responses;
    }

/**
* CLASSES
*/

    public class ClientIdGetNextHttpHandler extends HttpHandler {

        public override String getEndpoint(){
            return ClientIdCallout.getRequestURL() + '/' + planAcronym + '/' + METHOD_NAME;
        }

        public ClientIdGetNextResponse getParsedResponse(){
            return (ClientIdGetNextResponse) JSON.deserialize( parsedResponse.responseBody, ClientIdGetNextResponse.class );
        }

        public override String getErrorMessage(){
            Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped( parsedResponse.responseBody );

            return JSON.serialize( deserialized.get('apiErrorList') );
        }
    }

    public class ClientIdGetNextRequest {
        @InvocableVariable
        public string planAcronym;  
    }

    public class ClientIdGetNextResponse {
        @InvocableVariable
        public string nextAvailableClientId; 
        
        @InvocableVariable
        public string status;
        
        @InvocableVariable
        public integer statusCode;
    }

/**
* EXCEPTION CLASSES
*/

    class InvocableException extends Exception {}

}