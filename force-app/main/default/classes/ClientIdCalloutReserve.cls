/**
* @name ClientIdCalloutReserve
*
* @description this calss was built to help replace wv6_getNextavailableClientIdentifier and wv6_reserveClientIdentifier. 
* These callouts makes a callout directly to DDMI. It skips the call to the reverse proxy at DDMN. 
*
* @author Creed Interactive (Andrew Frederick) March 2022
*/
public class ClientIdCalloutReserve {

/**
* FIELDS
*/ 

    private static final String METHOD_NAME = 'reservations';

    // for date formatting below
    private static final String[] MONTHS = new String[]{
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
    };

/**
* INVOCABLE METHODS
*/

    /**
     * @name getNext
     * @description this method is called in the "Reserve Client Identifier" Flow. It makes a callout to a DDMI api. It actually reserves the client Id.
     * @param ClientIdReserveRequest[] reqs
     * @return ClientIdReserveResponse[] responses
     */
    @InvocableMethod(label='Reserve Client Identifier New' description='Callout to DDMI api to reserve Client Number')
    public static ClientIdReserveResponse[] reserve( ClientIdReserveRequest[] reqs ){

        ClientIdReserveRequest requestBody = reqs[0];
        requestBody.clientStartDate = getDateString( requestBody.clientStartDate );

        String requestBodyJSON =  JSON.serialize( requestBody );

        System.debug(requestBodyJSON);

        ClientIdReserveHttpHandler httpHandler = new ClientIdReserveHttpHandler();

        try {

            HttpRequest request = ClientIdCallout.getClientIdRequest();
            request.setBody( requestBodyJSON );

            httpHandler.send( request );

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
            
        ClientIdReserveResponse response = new ClientIdReserveResponse();
        response.message = httpHandler.getReponseBody();
        response.statusCode = httpHandler.getStatusCode();
        response.status = httpHandler.getStatus();
        
        ClientIdReserveResponse[] responses = new ClientIdReserveResponse[]{};
        responses.add( response );
        
        return responses;
    }

    /**
     * @name getNext
     * @description since this is all handled by a Screen Flow the date for "Start Date" comes in this specific format Jan 1, 2022. We need to parse that into
     * 01/01/2022. This is what is expected from the DDMI api.
     * @param String badDateFormat
     * @return String goodDateFormat
     */
    private static String getDateString( String badDateFormat ){
        String monthString = '';
        String dayString = '';
        String yearString = '';

        // replace coma and spaces
        badDateFormat = badDateFormat.replace(',', '').replace(' ', '-');

        // find the month and replace it with number and possible leading 0
        for( Integer i = 0; i < MONTHS.size(); i++ ){

            if( badDateFormat.contains(MONTHS[i]) ){

                Integer monthNumber = i + 1;

                if( monthNumber < 10 ){
                    monthString = '0' + String.valueOf(monthNumber);
                } else {
                    monthString = String.valueOf(monthNumber);
                }
                
                break;
            }
        }

        // find day
        dayString = badDateFormat.substringBetween('-', '-');

        // replace day with possible leading 0
        if( Integer.valueOf(dayString) < 10 ){
            dayString = '0' + dayString;
        }

        // find year
        yearString = badDateFormat.substringAfterLast('-');
        
        // return good date format
        return monthString + '/' +  dayString + '/' + yearString;
    }

/**
* CLASSES
*/

    public class ClientIdReserveHttpHandler extends HttpHandler {
        
        public override String getEndpoint(){
            return ClientIdCallout.getRequestURL() + '/' + METHOD_NAME;
        }

        protected override String getMethod(){
            return 'POST';
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
