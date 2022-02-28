/**
* @name ClientIdCalloutReserve
*
* @description this calss was built to help replace wv6_getNextavailableClientIdentifier and wv6_reserveClientIdentifier. 
* These callouts makes a callout directly to DDMI. It skips the call to the reverse proxy at DDMN. 
*
* @author Creed Interactive (Andrew Frederick) 2/24/22
*/
public class ClientIdCalloutReserve {
    
/**
* INVOCABLE METHODS
*/

    @InvocableMethod(label='Reserve Client Identifier New' description='Callout to DDMI api to reserve Client Number')
    public static ClientIdReserveResponse[] reserve( ClientIdReserveRequest[] reqs ){
        
        String requestBodyJSON =  JSON.serialize( reqs[0] );

        ClientIdReserveResponse[] responses = new ClientIdReserveResponse[]{};

        try {

            HttpRequest request = ClientIdCallout.getClientIdRequest();

            ClientIdReserveHttpHandler handler = new ClientIdReserveHttpHandler();
            handler.send( request );
            handler.checkErrors();
            
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

    public class ClientIdReserveHttpHandler extends HttpHandler {
        
        public override String getEndpoint(){
            return ClientIdCallout.getHostName() + '/api/v1/client/reservations';
        }

        public override String getMethod(){
            return 'GET';
        }

        public ClientIdReserveResponse getParsedResponse(){
            return (ClientIdReserveResponse) JSON.deserialize( parsedResponse.responseBody, ClientIdReserveResponse.class );
        }

        public override String getErrorMessage(){
            Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped( parsedResponse.responseBody );

            return JSON.serialize( deserialized.get('apiErrorList') );
        }
    }

    public class ClientIdReserveRequest {
        @InvocableVariable
        public string planAcronym; 
        
        @InvocableVariable
        public string clientSpecifiedIdentifier;
        
        @InvocableVariable
        public string clientName;     
        
        @InvocableVariable
        public string clientStartDate;
        
        @InvocableVariable
        public string reservedBy;  
        
        @InvocableVariable
        public string internalContactId;
    }

    public class ClientIdReserveResponse {
        @InvocableVariable
        public string message; 
        
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
