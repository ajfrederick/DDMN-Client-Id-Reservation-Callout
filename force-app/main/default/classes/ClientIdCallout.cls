/**
* @name ClientIdCallout
*
* @description this calss was built to help replace wv6_getNextavailableClientIdentifier and wv6_reserveClientIdentifier. 
* These callouts makes a callout directly to DDMI. It skips the call to the reverse proxy at DDMN. 
*
* @author Creed Interactive (Andrew Frederick) 2/24/22
*/
public without sharing class ClientIdCallout {

/**
* FIELDS
*/

    private static AccessTokenResponse accessTokenResponse {
        get {
            
            if( accessTokenResponse == null || accessTokenResponse.isExpired() ){
                getAccessToken();
            }

            return accessTokenResponse;
        }
        set;
    }

    // client credentials
    private static api_credential__mdt credential;

    private static Boolean isDev;

    /**
    * Static block to set credential and isDev variables;
    */
    static {

        try {
            
            credential = api_credential__mdt.getInstance('DDMI_Client_Id_Credentials');

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }

        try {
            
            // commented out on 2/25/22 because DDMI UAT is not configured to handle callouts from aaaall the SF IPs
            isDev = false; //[SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
    }

    private static final String URL_ENCODED_CONTENT_TYPE = 'application/x-www-form-urlencoded';
    private static final String JSON_CONTENT_TYPE = 'application/json;charset=UTF-8';

    private static final String GRANT_TYPE = 'client_credentials';
    private static final String SCOPE = 'DDMN_IVR_USER';

    private static final String CONTENT_LENGTH = '174';
    
/**
* ACTION METHODS
*/

    private static void getAccessToken(){

        if( credential == null || getClientId() == null || getClientSecret() == null ){
            throw new InvocableException('Client credentials not found for access token.');
        }

        String requestBody = getAccessTokenRequestBody();

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', URL_ENCODED_CONTENT_TYPE);
        request.setHeader('Content-Length', CONTENT_LENGTH);
        request.setBody( requestBody );

        try {

            AccessTokenHttpHandler handler = new AccessTokenHttpHandler();
            handler.send( request );
            handler.checkErrors();
            
            accessTokenResponse = handler.getParsedResponse();

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
* UTILITY METHODS
*/  

    private static String getAccessTokenRequestBody(){

        String requestBody = 'grant_type=' + EncodingUtil.urlEncode( GRANT_TYPE, 'UTF-8') + '&';
        requestBody += 'client_id=' + EncodingUtil.urlEncode( getClientId(), 'UTF-8') + '&';
        requestBody += 'client_secret=' + EncodingUtil.urlEncode( getClientSecret(), 'UTF-8') + '&';
        requestBody += 'scope=' + EncodingUtil.urlEncode( SCOPE, 'UTF-8');

        return requestBody;
    }

    public static HttpRequest getClientIdRequest(){

        if( !hasAccessToken() ){
            throw new InvocableException('Access token not retrieved');
        }

        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', JSON_CONTENT_TYPE );
        request.setHeader('access_token', accessTokenResponse.accessToken );
        request.setHeader('client_Id', getClientId() );
        request.setHeader('x-csrf-token', getXCSRFToken() );

        return request;
    }

    private static String getAccessTokenURL(){
        return isDev ? credential.Access_Token_URL_Dev__c : credential.Access_Token_URL__c;
    }

    public static String getHostName(){
        return isDev ? credential.Final_Request_URL_Dev__c : credential.Final_Request_URL__c;
    }

    private static String getClientId(){
        return isDev ? credential.Client_Id_Dev__c : credential.Client_Id__c;
    }

    private static String getClientSecret(){
        return isDev ? credential.Client_Secret_Dev__c : credential.Client_Secret__c;
    }

    private static String getXCSRFToken(){
        return credential.X_CSRF_Token__c;
    }

    public static Boolean hasAccessToken(){
        return accessTokenResponse != null && accessTokenResponse.hasToken() && !accessTokenResponse.isExpired();
    }

/**
* CLASSES
*/

    public class AccessTokenHttpHandler extends HttpHandler {

        private final String ACCESS_TOKEN_KEY = 'access_token';
        private final String EXPIRATION_KEY = 'expires_in';

        public override String getEndpoint(){
            return getAccessTokenURL();
        }

        public override String getMethod(){
            return 'POST';
        }

        public AccessTokenResponse getParsedResponse(){
            Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped( parsedResponse.responseBody );

            AccessTokenResponse response = new AccessTokenResponse();
            response.accessToken = getAccessToken( deserialized );
            response.expiration = getExpiration( deserialized );

            return response;
        }

        public override String getErrorMessage(){
            //Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped( parsed.responseBody );

            return parsedResponse.responseBody;
        }

        private String getAccessToken( Map<String, Object> deserialized ){
            return deserialized.containsKey(ACCESS_TOKEN_KEY) ? (String) deserialized.get(ACCESS_TOKEN_KEY) : '';
        }

        private DateTime getExpiration( Map<String, Object> deserialized ){
            return deserialized.containsKey(EXPIRATION_KEY) ? getDateTime( deserialized ) : null;
        }

        private DateTime getDateTime( Map<String, Object> deserialized ){
            Integer seconds = (Integer) deserialized.get(EXPIRATION_KEY) - 600; // expire in 1 hour but let's remove 10 minutes just for "travel safety"

            return DateTime.now().addSeconds(seconds);
        }
    }

    public class AccessTokenResponse {

        public String accessToken {get;set;}
        public DateTime expiration {get;set;}

        public Boolean hasToken(){
            return !String.isEmpty( accessToken );
        }

        public Boolean isExpired(){
            return expiration != null ? DateTime.now() > expiration : false; // false to avoid endless callout loop if expiration is null
        }
    }
    
/**
* EXCEPTION CLASSES
*/

    class InvocableException extends Exception {}

}