/**
* @name getNextAvailableClientIdentifier
*
* @description this callout is built to replace wv6_getNextavailableClientIdentifier. This callout makes a callout directly to DDMI.
* It skips the call to the reverse proxy at DDMN. 
*
* @author Creed Interactive (Andrew Frederick) 2/21/22
*/
public with sharing class getNextAvailableClientIdentifier {

/**
* FIELDS
*/

    private static final String accessTokenRequestContenType = 'application/x-www-form-urlencoded';
    private static final String clientIdReservationContentType = 'application/json;charset=UTF-8';

    // client credentials
    private static ddmi_api_credential__mdt credential;

    private static Boolean isDev = false;

    static {

        try {
            
            credential = ddmi_api_credential__mdt.getInstance('DDMI');

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }

        try {
              
            isDev = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
    }
    
/**
* INVOCABLE METHOD
*/

    @InvocableMethod(label='Get Next Available Client Identifier New' description='Callout to DDMI api for the next availeble client Number')
    public static NextAvailableClientIdentifierResponse[] getNextAvailableClientIdentifier( NextAvailableClientIdentifierRequest[] reqs ){
        
        String accessToken = getAccessToken();

        // Jet if we don't have the access token
        if( String.isBlank(accessToken) ){
            throw new InvocableException('Unable to retrieve an access token');
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');

        request.setHeader('Content-Type', clientIdReservationContentType );
        request.setHeader('access_token', accessToken );
        request.setHeader('client_Id', getClientId() );
        request.setHeader('x-csrf-token', getXCSRFToken() );

        request.setEndpoint( getNextAvailableClientIdURL( reqs[0].planAcronym ) );

        Http http = new Http();
		HttpResponse response = http.send(request);

        NextAvailableClientIdentifierResponse[] returnObjs = new NextAvailableClientIdentifierResponse[]{};

        try {

            NextAvailableClientIdResponseParser parser = new NextAvailableClientIdResponseParser( response );

            ResponseHandler handler = new ResponseHandler( parser );

            if( handler.hasErrors() ){
                throw new InvocableException( JSON.serialize( handler.getErrors() ) );
            }

            returnObjs.add( parser.getParsed() );

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
        
        return returnObjs;
    }

/**
* ACTION METHODS
*/

    private static String getAccessToken(){
        if( credential == null || getClientId() == null || getClientSecret() == null ) return null;

        String urlString = getAccessTokenURL() + '?';
        urlString += 'grant_type=client_credentials&';
        urlString += 'client_id=' + getClientId() + '&';
        urlString += 'client_secret=' + getClientSecret() +' &';
        urlString += 'scope=DDMN_IVR_USER';

        urlString = EncodingUtil.urlEncode( urlString, 'UTF-8');

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', accessTokenRequestContenType );
        request.setEndpoint( urlString );

        Http http = new Http();
        HttpResponse response = http.send(request);

        System.debug(response);

        String accessToken;

        try {

            AccessTokenResponseParser parser = new AccessTokenResponseParser( response );

            ResponseHandler handler = new ResponseHandler( parser );

            if( handler.hasErrors() ){
                throw new InvocableException( JSON.serialize( handler.getErrors() ) );
            }

            accessToken = parser.getParsed().access_token;

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }

        return accessToken;
    }

/**
* UTILITY METHODS
*/

    public static String getAccessTokenURL(){
        return isDev ? credential.Access_Token_URL_Dev__c : credential.Access_Token_URL__c;
    }

    public static String getClientId(){
        return isDev ? credential.Client_Id_Dev__c : credential.Client_Id__c;
    }

    public static String getClientSecret(){
        return isDev ? credential.Client_Secret_Dev__c : credential.Client_Secret__c;
    }

    public static String getXCSRFToken(){
        return credential.X_CSRF_Token__c;
    }

    public static String getNextAvailableClientIdURL( String planAcronym ){
        if( String.isBlank(planAcronym) ) planAcronym = 'DDMN';
        
        String hostname = isDev ? 'https://api.uat.rooseveltsolutions.com' : '';
   
        return hostname + '/api/v1/client/' + planAcronym + '/nextAvailableClientIdentifier';
    }

/**
* CLASSES
*/

    public abstract class ResponseParser {

        public ParsedResponse parsed {
            get {
                if( parsed == null ) parsed = new ParsedResponse();
                return parsed;
            }
            set;
        }

        public HttpResponse response {get;set;}

        public ResponseParser( HttpResponse response ){
            this.response = response;
        }

        public ParsedResponse parse(){
            parsed.responseBody = response.getBody();

            if( response.getStatusCode() > 299 ) parseErrors();

            return parsed;
        }

        public void parseErrors(){
            ResponseError error = new ResponseError();
            error.errorMessage = getErrorMessage();
            error.statusCode = response.getStatusCode();
            error.status = response.getStatus();
            
            parsed.errors.add( error );
        }

        public abstract String getErrorMessage();
    }

    public class AccessTokenResponseParser extends ResponseParser {

        public AccessTokenResponseParser( HttpResponse response ){
            super(response);
        }

        public AccessTokenResponse getParsed(){
            return (AccessTokenResponse) JSON.deserialize( parsed.responseBody, AccessTokenResponse.class );
        }

        public override String getErrorMessage(){
            Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped( parsed.responseBody );

            return JSON.serialize( deserialized.get('apiErrorList') ); // NEEDS TO CHANGE once we know how the errors are structured
        }
    }

    public class NextAvailableClientIdResponseParser extends ResponseParser {
        
        public NextAvailableClientIdResponseParser( HttpResponse response ){
            super(response);
        }

        public NextAvailableClientIdentifierResponse getParsed(){
            return (NextAvailableClientIdentifierResponse) JSON.deserialize( parsed.responseBody, NextAvailableClientIdentifierResponse.class );
        }

        public override String getErrorMessage(){
            Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped( parsed.responseBody );

            return JSON.serialize( deserialized.get('apiErrorList') );
        }
    }

    public class ResponseHandler {
        
        public ParsedResponse parsed {get;set;}

        public ResponseHandler( ResponseParser parser  ){
           this.parsed = parser.parse();
        }

        public Map<String, Object> getParsed(){
            return (Map<String, Object>) JSON.deserializeUntyped( parsed.responseBody );
        }

        public Boolean hasErrors(){
            return parsed.errors.size() > 0;
        }

        public ResponseError[] getErrors(){
            return parsed.errors;
        }
    }

    public class ParsedResponse {

        public String responseBody {
            get {
                if( responseBody == null ) responseBody = '{}';
                return responseBody;
            }
            set;
        }

        public ResponseError[] errors {
            get {
                if( errors == null ) errors = new ResponseError[]{};
                return errors;
            }
            set;
        }
    }

    public class AccessTokenResponse {
        public String access_token {get;set;}
    }

    public class ResponseError {
        public String errorMessage {get;set;}
        public Integer statusCode {get;set;}
        public String status {get;set;}
    }

/**
* INVOCABLE CLASSES
*/

    public class NextAvailableClientIdentifierRequest {
        @InvocableVariable
        public string planAcronym;  
    }

    public class NextAvailableClientIdentifierResponse {
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